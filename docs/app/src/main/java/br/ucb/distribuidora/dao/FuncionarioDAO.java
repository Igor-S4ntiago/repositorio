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

/**
 * CRUD de funcionario.
 *
 * Como cliente, funcionario e especializacao de pessoa, entao gravar
 * significa escrever em duas tabelas dentro de uma transacao.
 *
 * O campo supervisor e o autorrelacionamento da RN16: a lista de opcoes
 * sai da propria tabela funcionario.
 */
public class FuncionarioDAO implements CadastroDao {

    @Override
    public String titulo() {
        return "Funcionarios";
    }

    @Override
    public Campo[] campos() throws ErroNegocio {
        return new Campo[] {
            new Campo("nome", "Nome", Campo.Tipo.TEXTO, true),
            new Campo("cpf", "CPF (11 digitos)", Campo.Tipo.TEXTO, true),
            new Campo("telefone", "Telefone", Campo.Tipo.TEXTO, false),
            new Campo("email", "E-mail", Campo.Tipo.TEXTO, false),
            new Campo("cargo", "Cargo", Campo.Tipo.TEXTO, true),
            new Campo("data_admissao", "Admissao (aaaa-mm-dd)", Campo.Tipo.DATA, true),
            new Campo("ativo", "Ativo (1 = sim, 0 = nao)", Campo.Tipo.INTEIRO, true),
            new Campo("idsupervisor", "Supervisor", Campo.Tipo.LISTA, false,
                      listarSupervisores())
        };
    }

    /** Opcoes do autorrelacionamento. A primeira permite deixar em branco. */
    private List<ConsultaDAO.Opcao> listarSupervisores() throws ErroNegocio {
        String sql = "SELECT f.pessoa_idpessoa, CONCAT(p.nome, ' - ', f.cargo) "
                + "  FROM funcionario f "
                + "  JOIN pessoa      p ON p.idpessoa = f.pessoa_idpessoa "
                + " WHERE f.ativo = 1 "
                + " ORDER BY p.nome";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            List<ConsultaDAO.Opcao> lista = new ArrayList<>();
            lista.add(new ConsultaDAO.Opcao(0, "(sem supervisor)"));
            while (rs.next()) {
                lista.add(new ConsultaDAO.Opcao(rs.getInt(1), rs.getString(2)));
            }
            return lista;
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "listar os supervisores");
        }
    }

    @Override
    public Tabela listar(String filtro) throws ErroNegocio {
        String sql = "SELECT f.pessoa_idpessoa AS id, "
                + "       p.nome             AS nome, "
                + "       f.cargo            AS cargo, "
                + "       f.data_admissao    AS admissao, "
                + "       CASE WHEN f.ativo = 1 THEN 'Sim' ELSE 'Nao' END AS ativo, "
                + "       COALESCE(s.nome, '-') AS supervisor "
                + "  FROM funcionario f "
                + "  JOIN pessoa      p ON p.idpessoa = f.pessoa_idpessoa "
                + "  LEFT JOIN pessoa      s ON s.idpessoa = f.idsupervisor "
                + " WHERE p.nome LIKE ? OR f.cargo LIKE ? "
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
            throw TradutorErro.comoErroNegocio(e, "listar os funcionarios");
        }
    }

    @Override
    public Map<String, String> carregar(int id) throws ErroNegocio {
        String sql = "SELECT p.nome, p.cpf, p.telefone, p.email, "
                + "       f.cargo, f.data_admissao, f.ativo, f.idsupervisor "
                + "  FROM funcionario f "
                + "  JOIN pessoa      p ON p.idpessoa = f.pessoa_idpessoa "
                + " WHERE f.pessoa_idpessoa = ?";
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                Map<String, String> v = new LinkedHashMap<>();
                if (rs.next()) {
                    v.put("nome", rs.getString("nome"));
                    v.put("cpf", rs.getString("cpf"));
                    v.put("telefone", vazioSeNulo(rs.getString("telefone")));
                    v.put("email", vazioSeNulo(rs.getString("email")));
                    v.put("cargo", rs.getString("cargo"));
                    v.put("data_admissao", String.valueOf(rs.getDate("data_admissao")));
                    v.put("ativo", String.valueOf(rs.getInt("ativo")));
                    int sup = rs.getInt("idsupervisor");
                    v.put("idsupervisor", rs.wasNull() ? "0" : String.valueOf(sup));
                }
                return v;
            }
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "carregar o funcionario");
        }
    }

    private String vazioSeNulo(String s) {
        return s == null ? "" : s;
    }

    @Override
    public void inserir(Map<String, String> v) throws ErroNegocio {
        Connection con = null;
        try {
            con = Conexao.abrir();
            con.setAutoCommit(false);

            int idPessoa;
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO pessoa (nome, cpf, telefone, email) VALUES (?, ?, ?, ?)",
                    Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, v.get("nome"));
                ps.setString(2, v.get("cpf"));
                textoOuNulo(ps, 3, v.get("telefone"));
                textoOuNulo(ps, 4, v.get("email"));
                ps.executeUpdate();
                try (ResultSet chaves = ps.getGeneratedKeys()) {
                    chaves.next();
                    idPessoa = chaves.getInt(1);
                }
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO funcionario "
                    + "       (pessoa_idpessoa, cargo, data_admissao, ativo, idsupervisor) "
                    + "VALUES (?, ?, ?, ?, ?)")) {
                ps.setInt(1, idPessoa);
                ps.setString(2, v.get("cargo"));
                ps.setDate(3, Conversor.data(v.get("data_admissao"), "Admissao"));
                ps.setInt(4, Conversor.zeroOuUm(v.get("ativo"), "Ativo"));
                supervisorOuNulo(ps, 5, v.get("idsupervisor"));
                ps.executeUpdate();
            }

            con.commit();

        } catch (SQLException e) {
            reverter(con);
            throw TradutorErro.comoErroNegocio(e, "salvar o funcionario");
        } catch (ErroNegocio e) {
            reverter(con);
            throw e;
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

            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE pessoa SET nome = ?, cpf = ?, telefone = ?, email = ? "
                    + " WHERE idpessoa = ?")) {
                ps.setString(1, v.get("nome"));
                ps.setString(2, v.get("cpf"));
                textoOuNulo(ps, 3, v.get("telefone"));
                textoOuNulo(ps, 4, v.get("email"));
                ps.setInt(5, id);
                ps.executeUpdate();
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE funcionario "
                    + "   SET cargo = ?, data_admissao = ?, ativo = ?, idsupervisor = ? "
                    + " WHERE pessoa_idpessoa = ?")) {
                ps.setString(1, v.get("cargo"));
                ps.setDate(2, Conversor.data(v.get("data_admissao"), "Admissao"));
                ps.setInt(3, Conversor.zeroOuUm(v.get("ativo"), "Ativo"));
                supervisorOuNulo(ps, 4, v.get("idsupervisor"));
                ps.setInt(5, id);
                ps.executeUpdate();
            }

            con.commit();

        } catch (SQLException e) {
            reverter(con);
            throw TradutorErro.comoErroNegocio(e, "atualizar o funcionario");
        } catch (ErroNegocio e) {
            reverter(con);
            throw e;
        } finally {
            encerrar(con);
        }
    }

    @Override
    public void excluir(int id) throws ErroNegocio {
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(
                     "DELETE FROM pessoa WHERE idpessoa = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "excluir o funcionario");
        }
    }

    private void textoOuNulo(PreparedStatement ps, int pos, String valor) throws SQLException {
        if (valor == null || valor.isBlank()) {
            ps.setNull(pos, java.sql.Types.VARCHAR);
        } else {
            ps.setString(pos, valor.trim());
        }
    }

    /** Zero na tela significa "sem supervisor", que no banco e NULL (RN16). */
    private void supervisorOuNulo(PreparedStatement ps, int pos, String valor)
            throws SQLException {
        if (valor == null || valor.isBlank() || "0".equals(valor)) {
            ps.setNull(pos, java.sql.Types.INTEGER);
        } else {
            ps.setInt(pos, Integer.parseInt(valor));   // valor vem do combo, nunca digitado
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
