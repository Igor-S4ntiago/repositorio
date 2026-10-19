package br.ucb.distribuidora.dao;

import br.ucb.distribuidora.db.Conexao;
import br.ucb.distribuidora.db.ErroNegocio;
import br.ucb.distribuidora.db.TradutorErro;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * As duas consultas parametrizadas e o relatorio por visao, do B1.
 *
 * Todo filtro informado pelo usuario entra como parametro do
 * PreparedStatement, nunca concatenado no texto do SQL. E o que o B2
 * exige, e e o que faz a aplicacao resistir a injecao: o driver envia o
 * comando e os valores separados, de modo que o conteudo digitado nunca
 * e lido como comando.
 */
public class ConsultaDAO {

    // -----------------------------------------------------------------
    // Consulta parametrizada 1 -- faturamento por categoria no periodo
    // Juncao de quatro tabelas com agregacao. RN19: cancelado nao e venda.
    // -----------------------------------------------------------------
    private static final String SQL_FATURAMENTO =
            "SELECT c.nome                                          AS categoria, "
            + "       COUNT(DISTINCT i.pedido_idpedido)               AS pedidos, "
            + "       SUM(i.quantidade)                               AS unidades, "
            + "       ROUND(SUM(i.quantidade * i.preco_unitario), 2)  AS faturamento "
            + "  FROM categoria   c "
            + "  JOIN produto     p ON p.categoria_idcategoria = c.idcategoria "
            + "  JOIN item_pedido i ON i.produto_idproduto     = p.idproduto "
            + "  JOIN pedido      d ON d.idpedido              = i.pedido_idpedido "
            + " WHERE d.status <> 'CANCELADO' "
            + "   AND d.data_pedido >= ? "
            + "   AND d.data_pedido <  DATE_ADD(?, INTERVAL 1 DAY) "
            + "   AND c.nome LIKE ? "
            + " GROUP BY c.idcategoria, c.nome "
            + " ORDER BY faturamento DESC";

    /**
     * Quanto cada categoria faturou no periodo informado.
     *
     * @param de           data inicial, no formato aaaa-mm-dd
     * @param ate          data final, inclusive
     * @param filtroNome   parte do nome da categoria; vazio traz todas
     */
    public Tabela faturamentoPorCategoria(String de, String ate, String filtroNome)
            throws ErroNegocio {
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(SQL_FATURAMENTO)) {

            ps.setString(1, de);
            ps.setString(2, ate);
            ps.setString(3, "%" + filtroNome.trim() + "%");

            try (ResultSet rs = ps.executeQuery()) {
                return Tabela.de(rs);
            }
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "apurar o faturamento");
        }
    }

    // -----------------------------------------------------------------
    // Consulta parametrizada 2 -- o que precisa ser recomprado
    // Tres expressoes de tabela comuns. O limite de alerta nao e fixo:
    // depende do prazo do fornecedor mais lento de cada produto.
    // -----------------------------------------------------------------
    private static final String SQL_RECOMPRA =
            "WITH periodo AS ( "
            + "     SELECT DATEDIFF(MAX(data_pedido), MIN(data_pedido)) AS dias "
            + "       FROM pedido WHERE status <> 'CANCELADO' "
            + "), "
            + "venda_diaria AS ( "
            + "     SELECT i.produto_idproduto AS idproduto, "
            + "            SUM(i.quantidade)   AS total_vendido, "
            + "            SUM(i.quantidade) * 1.0 / (SELECT dias FROM periodo) AS media_dia "
            + "       FROM item_pedido i "
            + "       JOIN pedido d ON d.idpedido = i.pedido_idpedido "
            + "      WHERE d.status <> 'CANCELADO' "
            + "      GROUP BY i.produto_idproduto "
            + "), "
            + "prazo_fornecedor AS ( "
            + "     SELECT produto_idproduto       AS idproduto, "
            + "            MAX(prazo_fornecimento) AS maior_prazo "
            + "       FROM produto_fornecedor "
            + "      GROUP BY produto_idproduto "
            + ") "
            + "SELECT p.nome                                      AS produto, "
            + "       e.quantidade_atual                          AS em_estoque, "
            + "       ROUND(v.media_dia, 2)                       AS media_por_dia, "
            + "       ROUND(e.quantidade_atual / v.media_dia, 1)  AS dias_de_cobertura, "
            + "       z.maior_prazo                               AS prazo_fornecedor, "
            + "       z.maior_prazo + ?                           AS ponto_de_recompra "
            + "  FROM venda_diaria     v "
            + "  JOIN produto          p ON p.idproduto         = v.idproduto "
            + "  JOIN estoque          e ON e.produto_idproduto = p.idproduto "
            + "  JOIN prazo_fornecedor z ON z.idproduto         = p.idproduto "
            + " WHERE v.media_dia > 0 "
            + "   AND e.quantidade_atual / v.media_dia < z.maior_prazo + ? "
            + " ORDER BY dias_de_cobertura";

    /**
     * Produtos cujo estoque nao dura ate a proxima entrega do fornecedor.
     *
     * @param folgaDias margem de seguranca somada ao prazo do fornecedor
     */
    public Tabela produtosParaRecomprar(int folgaDias) throws ErroNegocio {
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(SQL_RECOMPRA)) {

            ps.setInt(1, folgaDias);
            ps.setInt(2, folgaDias);

            try (ResultSet rs = ps.executeQuery()) {
                return Tabela.de(rs);
            }
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "levantar os produtos a recomprar");
        }
    }

    // -----------------------------------------------------------------
    // Relatorio alimentado por visao (B1)
    // A tela nao conhece a regra de apuracao: ela so le a visao.
    // -----------------------------------------------------------------
    public Tabela relatorioFaturamento() throws ErroNegocio {
        String sql = "SELECT categoria, pedidos, unidades_vendidas, faturamento "
                + "  FROM vw_faturamento_categoria "
                + " ORDER BY faturamento DESC";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return Tabela.de(rs);
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "abrir o relatorio");
        }
    }

    // -----------------------------------------------------------------
    // Apoio as telas
    // -----------------------------------------------------------------

    /** Clientes para o combo da tela de venda. */
    public List<Opcao> listarClientes() throws ErroNegocio {
        String sql = "SELECT c.pessoa_idpessoa, p.nome "
                + "  FROM cliente c "
                + "  JOIN pessoa  p ON p.idpessoa = c.pessoa_idpessoa "
                + " ORDER BY p.nome";
        return carregarOpcoes(sql, "listar os clientes");
    }

    /**
     * Produtos com saldo, para o combo da tela de venda. O filtro por
     * nome usa LIKE com parametro -- e esta consulta que serve de
     * demonstracao de resistencia a injecao de SQL no relatorio (B2).
     */
    public List<Opcao> listarProdutosComSaldo(String filtroNome) throws ErroNegocio {
        String sql = "SELECT idproduto, "
                + "       CONCAT(produto, '  (saldo ', quantidade_atual, ')') AS rotulo "
                + "  FROM vw_posicao_estoque "
                + " WHERE produto LIKE ? "
                + " ORDER BY produto";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, "%" + filtroNome.trim() + "%");
            try (ResultSet rs = ps.executeQuery()) {
                List<Opcao> lista = new ArrayList<>();
                while (rs.next()) {
                    lista.add(new Opcao(rs.getInt(1), rs.getString(2)));
                }
                return lista;
            }
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "listar os produtos");
        }
    }

    private List<Opcao> carregarOpcoes(String sql, String acao) throws ErroNegocio {
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            List<Opcao> lista = new ArrayList<>();
            while (rs.next()) {
                lista.add(new Opcao(rs.getInt(1), rs.getString(2)));
            }
            return lista;
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, acao);
        }
    }

    /** Par identificador / texto, para preencher combos. */
    public static class Opcao {
        private final int id;
        private final String texto;

        public Opcao(int id, String texto) {
            this.id = id;
            this.texto = texto;
        }

        public int getId() {
            return id;
        }

        @Override
        public String toString() {
            return texto;
        }
    }
}
