package br.ucb.distribuidora.dao;

import br.ucb.distribuidora.db.Conexao;
import br.ucb.distribuidora.db.ErroNegocio;
import br.ucb.distribuidora.db.TradutorErro;
import br.ucb.distribuidora.seguranca.Senha;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Login da aplicacao, com senha guardada em hash e sal (B5).
 */
public class UsuarioDAO {

    /** Usuario autenticado, com o perfil que define o que ele pode ver. */
    public static class Usuario {
        private final int id;
        private final String login;
        private final String perfil;

        public Usuario(int id, String login, String perfil) {
            this.id = id;
            this.login = login;
            this.perfil = perfil;
        }

        public int getId() {
            return id;
        }

        public String getLogin() {
            return login;
        }

        public String getPerfil() {
            return perfil;
        }

        public boolean ehAdmin() {
            return "ADMIN".equals(perfil);
        }
    }

    /**
     * Confere login e senha.
     *
     * A senha digitada nao viaja ate o banco: o que o SQL busca e o sal e
     * o hash gravados, e a comparacao acontece aqui, em memoria. Assim a
     * senha em texto claro nunca aparece em log de consulta do MySQL.
     *
     * @return o usuario autenticado, ou null se login ou senha estiverem errados
     */
    public Usuario autenticar(String login, char[] senha) throws ErroNegocio {
        String sql = "SELECT idusuario, login, perfil, senha_hash, senha_sal "
                + "  FROM usuario "
                + " WHERE login = ? AND ativo = 1";

        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, login);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                boolean confere = Senha.conferir(
                        senha, rs.getString("senha_sal"), rs.getString("senha_hash"));
                if (!confere) {
                    return null;
                }
                return new Usuario(
                        rs.getInt("idusuario"),
                        rs.getString("login"),
                        rs.getString("perfil"));
            }
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "verificar o login");
        } finally {
            // Apaga a senha da memoria assim que ela deixa de ser necessaria.
            java.util.Arrays.fill(senha, '\0');
        }
    }

    /**
     * Cria um usuario. Cada senha recebe um sal proprio, sorteado na hora.
     */
    public void criar(String login, char[] senha, String perfil, Integer idFuncionario)
            throws ErroNegocio {

        String sal = Senha.novoSal();
        String hash = Senha.calcularHash(senha, sal);
        java.util.Arrays.fill(senha, '\0');

        String sql = "INSERT INTO usuario "
                + "       (login, senha_hash, senha_sal, perfil, ativo, "
                + "        funcionario_pessoa_idpessoa) "
                + "VALUES (?, ?, ?, ?, 1, ?)";

        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, login);
            ps.setString(2, hash);
            ps.setString(3, sal);
            ps.setString(4, perfil);
            if (idFuncionario == null) {
                ps.setNull(5, java.sql.Types.INTEGER);
            } else {
                ps.setInt(5, idFuncionario);
            }
            ps.executeUpdate();

        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "criar o usuario");
        }
    }

    /** Quantos usuarios existem. Serve para saber se o banco ja foi semeado. */
    public int contar() throws ErroNegocio {
        try (Connection con = Conexao.abrir();
             PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM usuario");
             ResultSet rs = ps.executeQuery()) {
            rs.next();
            return rs.getInt(1);
        } catch (SQLException e) {
            throw TradutorErro.comoErroNegocio(e, "contar os usuarios");
        }
    }
}
