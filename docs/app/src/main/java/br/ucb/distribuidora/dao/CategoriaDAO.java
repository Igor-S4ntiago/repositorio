package br.ucb.distribuidora.dao;

import br.ucb.distribuidora.db.Conexao;
import br.ucb.distribuidora.db.ErroNegocio;
import br.ucb.distribuidora.db.TradutorErro;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * CRUD de categoria.
 *
 * A categoria e o que menos tem colunas no modelo, mas e boa para mostrar
 * duas restricoes trabalhando:
 *
 *   uq_categoria_nome   recusa nome repetido
 *   fk_produto_categoria  impede apagar categoria que tenha produto
 *
 * A listagem traz a contagem de produtos de cada uma justamente para que
 * se veja, antes de tentar, qual delas o banco vai recusar excluir.
 */
public class CategoriaDAO implements CadastroDao {

    @Override
    public String titulo() {
        return "Categorias";
    }

    @Override
    public Campo[] campos() {
        return new Campo[] {
            new Campo("nome", "Nome", Campo.Tipo.TEXTO, true),
            new Campo("descricao", "Descricao", Campo.Tipo.TEXTO, false)
        };
    }

    @Override
    public Tabela listar(String filtro) throws ErroNegocio {
        String sql = "SELECT c.idcategoria AS id, "
                + "       c.nome        AS categoria, "
                + "       COALESCE(c.descricao, '-') AS descricao, "
                + "       COUNT(p.idproduto)         AS produtos "
                + "  FROM categoria c "
                + "  LEFT JOIN produto p ON p.categoria_idcategoria = c.idcategoria "
                + " WHERE c.nome LIKE ? OR COALESCE(c.descricao, '') LIKE ? "
                + " GROUP BY c.idcategoria, c.nome, c.descricao "
                + " ORDER BY c.nome";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            String busca = "%" + filtro.trim() + "%";
            ps.setString(1, busca);
            ps.setString(2, busca);
            try (ResultSet rs = ps.executeQuery()) {
                return Tabela.de(rs);
            }
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "listar as categorias");
        }
    }

    @Override
    public Map<String, String> carregar(int id) throws ErroNegocio {
        String sql = "SELECT nome, descricao FROM categoria WHERE idcategoria = ?";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                Map<String, String> v = new LinkedHashMap<>();
                if (rs.next()) {
                    v.put("nome", rs.getString("nome"));
                    String d = rs.getString("descricao");
                    v.put("descricao", d == null ? "" : d);
                }
                return v;
            }
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "carregar a categoria");
        }
    }

    @Override
    public void inserir(Map<String, String> v) throws ErroNegocio {
        String sql = "INSERT INTO categoria (nome, descricao) VALUES (?, ?)";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            preencher(ps, v);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "salvar a categoria");
        }
    }

    @Override
    public void atualizar(int id, Map<String, String> v) throws ErroNegocio {
        String sql = "UPDATE categoria SET nome = ?, descricao = ? "
                + " WHERE idcategoria = ?";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            preencher(ps, v);
            ps.setInt(3, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "atualizar a categoria");
        }
    }

    private void preencher(PreparedStatement ps, Map<String, String> v)
            throws SQLException {
        ps.setString(1, v.get("nome"));
        String descricao = v.get("descricao");
        if (descricao == null || descricao.isBlank()) {
            ps.setNull(2, java.sql.Types.VARCHAR);
        } else {
            ps.setString(2, descricao.trim());
        }
    }

    @Override
    public void excluir(int id) throws ErroNegocio {
        // A chave estrangeira de produto para categoria e RESTRICT (RN04):
        // categoria com produto nao pode ser apagada. O TradutorErro
        // transforma essa recusa em mensagem na tela.
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(
                     "DELETE FROM categoria WHERE idcategoria = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "excluir a categoria");
        }
    }
}
