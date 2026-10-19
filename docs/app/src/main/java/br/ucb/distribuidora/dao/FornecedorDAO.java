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

/** CRUD de fornecedor. Entidade de tabela unica, o cadastro mais simples. */
public class FornecedorDAO implements CadastroDao {

    @Override
    public String titulo() {
        return "Fornecedores";
    }

    @Override
    public Campo[] campos() {
        return new Campo[] {
            new Campo("razao_social", "Razao social", Campo.Tipo.TEXTO, true),
            new Campo("cnpj", "CNPJ (14 digitos)", Campo.Tipo.TEXTO, true),
            new Campo("telefone", "Telefone", Campo.Tipo.TEXTO, false),
            new Campo("email", "E-mail", Campo.Tipo.TEXTO, false)
        };
    }

    @Override
    public Tabela listar(String filtro) throws ErroNegocio {
        String sql = "SELECT f.idfornecedor AS id, "
                + "       f.razao_social  AS razao_social, "
                + "       f.cnpj          AS cnpj, "
                + "       COALESCE(f.telefone, '-') AS telefone, "
                + "       COALESCE(f.email, '-')    AS email, "
                + "       COUNT(pf.produto_idproduto) AS produtos "
                + "  FROM fornecedor f "
                + "  LEFT JOIN produto_fornecedor pf "
                + "         ON pf.fornecedor_idfornecedor = f.idfornecedor "
                + " WHERE f.razao_social LIKE ? OR f.cnpj LIKE ? "
                + " GROUP BY f.idfornecedor, f.razao_social, f.cnpj, f.telefone, f.email "
                + " ORDER BY f.razao_social";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            String busca = "%" + filtro.trim() + "%";
            ps.setString(1, busca);
            ps.setString(2, busca);
            try (ResultSet rs = ps.executeQuery()) {
                return Tabela.de(rs);
            }
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "listar os fornecedores");
        }
    }

    @Override
    public Map<String, String> carregar(int id) throws ErroNegocio {
        String sql = "SELECT razao_social, cnpj, telefone, email "
                + "  FROM fornecedor WHERE idfornecedor = ?";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                Map<String, String> v = new LinkedHashMap<>();
                if (rs.next()) {
                    v.put("razao_social", rs.getString("razao_social"));
                    v.put("cnpj", rs.getString("cnpj"));
                    v.put("telefone", rs.getString("telefone") == null
                            ? "" : rs.getString("telefone"));
                    v.put("email", rs.getString("email") == null
                            ? "" : rs.getString("email"));
                }
                return v;
            }
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "carregar o fornecedor");
        }
    }

    @Override
    public void inserir(Map<String, String> v) throws ErroNegocio {
        String sql = "INSERT INTO fornecedor (razao_social, cnpj, telefone, email) "
                + "VALUES (?, ?, ?, ?)";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            preencher(ps, v);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "salvar o fornecedor");
        }
    }

    @Override
    public void atualizar(int id, Map<String, String> v) throws ErroNegocio {
        String sql = "UPDATE fornecedor "
                + "   SET razao_social = ?, cnpj = ?, telefone = ?, email = ? "
                + " WHERE idfornecedor = ?";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            preencher(ps, v);
            ps.setInt(5, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "atualizar o fornecedor");
        }
    }

    private void preencher(PreparedStatement ps, Map<String, String> v) throws SQLException {
        ps.setString(1, v.get("razao_social"));
        ps.setString(2, v.get("cnpj"));
        String tel = v.get("telefone");
        String mail = v.get("email");
        if (tel == null || tel.isBlank()) {
            ps.setNull(3, java.sql.Types.VARCHAR);
        } else {
            ps.setString(3, tel.trim());
        }
        if (mail == null || mail.isBlank()) {
            ps.setNull(4, java.sql.Types.VARCHAR);
        } else {
            ps.setString(4, mail.trim());
        }
    }

    @Override
    public void excluir(int id) throws ErroNegocio {
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(
                     "DELETE FROM fornecedor WHERE idfornecedor = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "excluir o fornecedor");
        }
    }
}
