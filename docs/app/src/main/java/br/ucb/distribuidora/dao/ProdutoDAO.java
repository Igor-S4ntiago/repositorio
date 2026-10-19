package br.ucb.distribuidora.dao;

import br.ucb.distribuidora.db.Conexao;
import br.ucb.distribuidora.db.ErroNegocio;
import br.ucb.distribuidora.db.TradutorErro;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** CRUD de produto. */
public class ProdutoDAO implements CadastroDao {

    @Override
    public String titulo() {
        return "Produtos";
    }

    @Override
    public Campo[] campos() throws ErroNegocio {
        return new Campo[] {
            new Campo("nome", "Nome", Campo.Tipo.TEXTO, true),
            new Campo("preco_venda", "Preco de venda", Campo.Tipo.DECIMAL, true),
            new Campo("unidade_medida", "Unidade (UN, CX, FD...)", Campo.Tipo.TEXTO, true),
            new Campo("categoria_idcategoria", "Categoria", Campo.Tipo.LISTA, true,
                      listarCategorias())
        };
    }

    private List<ConsultaDAO.Opcao> listarCategorias() throws ErroNegocio {
        String sql = "SELECT idcategoria, nome FROM categoria ORDER BY nome";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            List<ConsultaDAO.Opcao> lista = new ArrayList<>();
            while (rs.next()) {
                lista.add(new ConsultaDAO.Opcao(rs.getInt(1), rs.getString(2)));
            }
            return lista;
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "listar as categorias");
        }
    }

    @Override
    public Tabela listar(String filtro) throws ErroNegocio {
        String sql = "SELECT p.idproduto        AS id, "
                + "       p.nome              AS produto, "
                + "       c.nome              AS categoria, "
                + "       p.preco_venda       AS preco, "
                + "       p.unidade_medida    AS unidade, "
                + "       COALESCE(e.quantidade_atual, 0) AS estoque "
                + "  FROM produto   p "
                + "  JOIN categoria c ON c.idcategoria       = p.categoria_idcategoria "
                + "  LEFT JOIN estoque e ON e.produto_idproduto = p.idproduto "
                + " WHERE p.nome LIKE ? "
                + " ORDER BY p.nome";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, "%" + filtro.trim() + "%");
            try (ResultSet rs = ps.executeQuery()) {
                return Tabela.de(rs);
            }
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "listar os produtos");
        }
    }

    @Override
    public Map<String, String> carregar(int id) throws ErroNegocio {
        String sql = "SELECT nome, preco_venda, unidade_medida, categoria_idcategoria "
                + "  FROM produto WHERE idproduto = ?";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                Map<String, String> v = new LinkedHashMap<>();
                if (rs.next()) {
                    v.put("nome", rs.getString("nome"));
                    v.put("preco_venda", rs.getBigDecimal("preco_venda").toPlainString());
                    v.put("unidade_medida", rs.getString("unidade_medida"));
                    v.put("categoria_idcategoria",
                          String.valueOf(rs.getInt("categoria_idcategoria")));
                }
                return v;
            }
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "carregar o produto");
        }
    }

    /**
     * Cria o produto e, junto, a sua posicao de estoque zerada.
     *
     * As duas coisas numa transacao so, porque produto sem linha em
     * estoque e um registro pela metade: a visao vw_posicao_estoque junta
     * as duas tabelas, e a tela de venda le dessa visao. Um produto
     * gravado sozinho existiria no cadastro e seria invisivel para a
     * venda, que e pior do que nao existir -- ninguem procuraria o erro
     * no lugar certo.
     *
     * Nascer com saldo zero tambem e o comportamento correto do dominio:
     * o produto so passa a ter saldo quando entrar mercadoria, e ate la
     * a RN11 recusa qualquer venda dele.
     */
    @Override
    public void inserir(Map<String, String> v) throws ErroNegocio {
        Connection con = null;
        try {
            con = Conexao.abrir();
            con.setAutoCommit(false);

            int idProduto;
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO produto "
                    + "       (nome, preco_venda, unidade_medida, categoria_idcategoria) "
                    + "VALUES (?, ?, ?, ?)",
                    Statement.RETURN_GENERATED_KEYS)) {
                preencher(ps, v);
                ps.executeUpdate();
                try (ResultSet chaves = ps.getGeneratedKeys()) {
                    chaves.next();
                    idProduto = chaves.getInt(1);
                }
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO estoque "
                    + "       (produto_idproduto, quantidade_atual, data_atualizacao) "
                    + "VALUES (?, 0, NOW())")) {
                ps.setInt(1, idProduto);
                ps.executeUpdate();
            }

            con.commit();

        } catch (SQLException e) {
            reverter(con);
            throw TradutorErro.comoErroNegocio(e, "salvar o produto");
        } catch (ErroNegocio e) {
            reverter(con);
            throw e;
        } finally {
            encerrar(con);
        }
    }

    @Override
    public void atualizar(int id, Map<String, String> v) throws ErroNegocio {
        String sql = "UPDATE produto "
                + "   SET nome = ?, preco_venda = ?, unidade_medida = ?, "
                + "       categoria_idcategoria = ? "
                + " WHERE idproduto = ?";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            preencher(ps, v);
            ps.setInt(5, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "atualizar o produto");
        }
    }

    private void preencher(PreparedStatement ps, Map<String, String> v)
            throws SQLException, ErroNegocio {
        ps.setString(1, v.get("nome"));
        ps.setBigDecimal(2, Conversor.decimal(v.get("preco_venda"), "Preco de venda"));
        ps.setString(3, v.get("unidade_medida"));
        ps.setInt(4, Conversor.inteiro(v.get("categoria_idcategoria"), "Categoria"));
    }

    /**
     * Exclui o produto e a sua posicao de estoque, nessa ordem.
     *
     * A ordem e obrigatoria: fk_estoque_produto e RESTRICT, entao o
     * produto nao sai enquanto tiver estoque. Ja fk_movimentacao_estoque
     * e CASCADE, de modo que apagar a linha de estoque leva junto o
     * historico de movimentacoes dela.
     *
     * E por isso que as duas exclusoes vao numa transacao. A chave
     * estrangeira de item_pedido para produto e RESTRICT: se o produto ja
     * foi vendido, o segundo DELETE falha, e sem a transacao o historico
     * de movimentacoes teria sido apagado por um comando que no fim nao
     * se completou. Com ela, o ROLLBACK devolve tudo.
     */
    @Override
    public void excluir(int id) throws ErroNegocio {
        Connection con = null;
        try {
            con = Conexao.abrir();
            con.setAutoCommit(false);

            try (PreparedStatement ps = con.prepareStatement(
                    "DELETE FROM estoque WHERE produto_idproduto = ?")) {
                ps.setInt(1, id);
                ps.executeUpdate();
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "DELETE FROM produto WHERE idproduto = ?")) {
                ps.setInt(1, id);
                ps.executeUpdate();
            }

            con.commit();

        } catch (SQLException e) {
            reverter(con);
            throw TradutorErro.comoErroNegocio(e, "excluir o produto");
        } finally {
            encerrar(con);
        }
    }

    private void reverter(Connection con) {
        if (con != null) {
            try {
                con.rollback();
            } catch (SQLException ignorado) {
                // conexao ja caiu
            }
        }
    }

    private void encerrar(Connection con) {
        if (con != null) {
            try {
                con.setAutoCommit(true);
                con.close();
            } catch (SQLException ignorado) {
                // nada util a fazer
            }
        }
    }
}
