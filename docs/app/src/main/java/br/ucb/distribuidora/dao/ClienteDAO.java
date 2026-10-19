package br.ucb.distribuidora.dao;

import br.ucb.distribuidora.db.Conexao;
import br.ucb.distribuidora.db.ErroNegocio;
import br.ucb.distribuidora.db.TradutorErro;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * CRUD de cliente.
 *
 * Cliente e uma especializacao de pessoa: os dados de identificacao ficam
 * em pessoa e os de compra ficam em cliente, com a mesma chave primaria.
 * Por isso gravar um cliente significa gravar em duas tabelas, e isso vai
 * dentro de uma transacao -- se a segunda insercao falhar, a pessoa
 * solta nao pode sobrar no banco.
 */
public class ClienteDAO implements CadastroDao {

    @Override
    public String titulo() {
        return "Clientes";
    }

    @Override
    public Campo[] campos() {
        return new Campo[] {
            new Campo("nome", "Nome", Campo.Tipo.TEXTO, true),
            new Campo("cpf", "CPF (11 digitos)", Campo.Tipo.TEXTO, true),
            new Campo("telefone", "Telefone", Campo.Tipo.TEXTO, false),
            new Campo("email", "E-mail", Campo.Tipo.TEXTO, false),
            new Campo("endereco", "Endereco de entrega", Campo.Tipo.TEXTO, false)
        };
    }

    @Override
    public Tabela listar(String filtro) throws ErroNegocio {
        String sql = "SELECT c.pessoa_idpessoa AS id, "
                + "       p.nome             AS nome, "
                + "       p.cpf              AS cpf, "
                + "       COALESCE(p.telefone, '-') AS telefone, "
                + "       COALESCE(c.endereco, '-') AS endereco, "
                + "       c.data_cadastro    AS cadastrado_em "
                + "  FROM cliente c "
                + "  JOIN pessoa  p ON p.idpessoa = c.pessoa_idpessoa "
                + " WHERE p.nome LIKE ? OR p.cpf LIKE ? "
                + " ORDER BY p.nome";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            String busca = "%" + filtro.trim() + "%";
            ps.setString(1, busca);
            ps.setString(2, busca);
            try (ResultSet rs = ps.executeQuery()) {
                return Tabela.de(rs);
            }
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "listar os clientes");
        }
    }

    @Override
    public Map<String, String> carregar(int id) throws ErroNegocio {
        String sql = "SELECT p.nome, p.cpf, p.telefone, p.email, c.endereco "
                + "  FROM cliente c "
                + "  JOIN pessoa  p ON p.idpessoa = c.pessoa_idpessoa "
                + " WHERE c.pessoa_idpessoa = ?";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                Map<String, String> v = new LinkedHashMap<>();
                if (rs.next()) {
                    v.put("nome", rs.getString("nome"));
                    v.put("cpf", rs.getString("cpf"));
                    v.put("telefone", texto(rs.getString("telefone")));
                    v.put("email", texto(rs.getString("email")));
                    v.put("endereco", texto(rs.getString("endereco")));
                }
                return v;
            }
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "carregar o cliente");
        }
    }

    private String texto(String s) {
        return s == null ? "" : s;
    }

    /** Campo opcional em branco vira NULL no banco, e nao string vazia. */
    private void opcional(PreparedStatement ps, int pos, String valor) throws SQLException {
        if (valor == null || valor.isBlank()) {
            ps.setNull(pos, java.sql.Types.VARCHAR);
        } else {
            ps.setString(pos, valor.trim());
        }
    }

    @Override
    public void inserir(Map<String, String> v) throws ErroNegocio {
        Connection con = null;
        try {
            con = Conexao.abrir();
            con.setAutoCommit(false);

            int idPessoa;
            String sqlPessoa = "INSERT INTO pessoa (nome, cpf, telefone, email) "
                    + "VALUES (?, ?, ?, ?)";
            try (PreparedStatement ps = con.prepareStatement(
                    sqlPessoa, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, v.get("nome"));
                ps.setString(2, v.get("cpf"));
                opcional(ps, 3, v.get("telefone"));
                opcional(ps, 4, v.get("email"));
                ps.executeUpdate();
                try (ResultSet chaves = ps.getGeneratedKeys()) {
                    chaves.next();
                    idPessoa = chaves.getInt(1);
                }
            }

            String sqlCliente = "INSERT INTO cliente "
                    + "       (pessoa_idpessoa, endereco, data_cadastro) "
                    + "VALUES (?, ?, NOW())";
            try (PreparedStatement ps = con.prepareStatement(sqlCliente)) {
                ps.setInt(1, idPessoa);
                opcional(ps, 2, v.get("endereco"));
                ps.executeUpdate();
            }

            con.commit();

        } catch (SQLException e) {
            reverter(con);
            throw TradutorErro.comoErroNegocio(e, "salvar o cliente");
        } finally {
            encerrar(con);
        }
    }

    @Override
    public void atualizar(int id, Map<String, String> v) throws ErroNegocio {
        Connection con = null;
        try {
            con = Conexao.abrir();
            con.setAutoCommit(false);

            String sqlPessoa = "UPDATE pessoa "
                    + "   SET nome = ?, cpf = ?, telefone = ?, email = ? "
                    + " WHERE idpessoa = ?";
            try (PreparedStatement ps = con.prepareStatement(sqlPessoa)) {
                ps.setString(1, v.get("nome"));
                ps.setString(2, v.get("cpf"));
                opcional(ps, 3, v.get("telefone"));
                opcional(ps, 4, v.get("email"));
                ps.setInt(5, id);
                ps.executeUpdate();
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE cliente SET endereco = ? WHERE pessoa_idpessoa = ?")) {
                opcional(ps, 1, v.get("endereco"));
                ps.setInt(2, id);
                ps.executeUpdate();
            }

            con.commit();

        } catch (SQLException e) {
            reverter(con);
            throw TradutorErro.comoErroNegocio(e, "atualizar o cliente");
        } finally {
            encerrar(con);
        }
    }

    @Override
    public void excluir(int id) throws ErroNegocio {
        // Basta apagar a pessoa: a chave estrangeira de cliente para
        // pessoa e CASCADE, entao a linha de cliente vai junto. Se o
        // cliente ja tiver pedidos, a chave de pedido para cliente e
        // RESTRICT e o banco recusa -- que e o comportamento desejado.
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(
                     "DELETE FROM pessoa WHERE idpessoa = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "excluir o cliente");
        }
    }

    private void reverter(Connection con) {
        if (con != null) {
            try {
                con.rollback();
            } catch (SQLException ignorado) {
                // conexao ja caiu; o InnoDB desfaz sozinho
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
