package br.ucb.distribuidora;

import br.ucb.distribuidora.dao.UsuarioDAO;
import br.ucb.distribuidora.db.Conexao;
import br.ucb.distribuidora.db.ErroNegocio;
import br.ucb.distribuidora.seguranca.Senha;
import br.ucb.distribuidora.ui.Aviso;
import br.ucb.distribuidora.ui.JanelaPrincipal;
import br.ucb.distribuidora.ui.TelaConexao;
import br.ucb.distribuidora.ui.TelaLogin;

import javax.swing.JOptionPane;
import javax.swing.SwingUtilities;
import javax.swing.UIManager;

/**
 * Ponto de entrada da aplicacao.
 *
 * Tem dois modos:
 *
 *   java -jar distribuidora-app.jar
 *       abre a tela de login e, em seguida, a janela principal. Na
 *       primeira execucao em uma maquina nova, antes do login, pede os
 *       dados de acesso ao MySQL e grava o config.properties.
 *
 *   java -jar distribuidora-app.jar --criar-usuario login senha PERFIL
 *       cria um usuario da aplicacao pelo terminal. Serve para criar o
 *       primeiro ADMIN, ja que sem usuario nao ha como entrar na tela.
 *       A senha e gravada em hash com sal, nunca em texto claro.
 *
 *   java -jar distribuidora-app.jar --hash senha
 *       imprime um par sal/hash. Util para montar um INSERT a mao no
 *       script de carga.
 */
public class Main {

    public static void main(String[] args) {
        if (args.length > 0 && "--criar-usuario".equals(args[0])) {
            criarUsuario(args);
            return;
        }
        if (args.length > 0 && "--hash".equals(args[0])) {
            gerarHash(args);
            return;
        }
        abrirInterface();
    }

    // -----------------------------------------------------------------
    // Interface grafica
    // -----------------------------------------------------------------
    private static void abrirInterface() {
        SwingUtilities.invokeLater(() -> {
            try {
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
            } catch (Exception ignorado) {
                // Segue com a aparencia padrao do Java.
            }

            // Antes de qualquer tela, garante que ha conexao. Sem isso a
            // primeira falha apareceria na tela de login, como se fosse
            // problema de usuario e senha da aplicacao, quando na verdade
            // e do acesso ao MySQL -- duas coisas diferentes que seria
            // ruim confundir justamente na hora de entrar.
            if (!Conexao.estaConfigurada() || Conexao.testar() != null) {
                if (!TelaConexao.configurar()) {
                    System.exit(0);
                }
            }

            TelaLogin login = new TelaLogin(null);
            login.setVisible(true);          // bloqueia ate fechar

            UsuarioDAO.Usuario usuario = login.getAutenticado();
            if (usuario == null) {
                System.exit(0);              // o usuario desistiu de entrar
            }

            new JanelaPrincipal(usuario).setVisible(true);
        });
    }

    // -----------------------------------------------------------------
    // Modos de terminal
    // -----------------------------------------------------------------
    private static void criarUsuario(String[] args) {
        if (args.length != 4) {
            System.out.println(
                    "Uso: java -jar distribuidora-app.jar --criar-usuario "
                    + "<login> <senha> <ADMIN|VENDEDOR|ESTOQUISTA>");
            return;
        }
        try {
            new UsuarioDAO().criar(args[1], args[2].toCharArray(), args[3], null);
            System.out.println("Usuario '" + args[1] + "' criado com perfil "
                    + args[3] + ".");
        } catch (ErroNegocio e) {
            System.out.println("Nao foi possivel criar o usuario: " + e.getMessage());
        }
    }

    private static void gerarHash(String[] args) {
        if (args.length != 2) {
            System.out.println("Uso: java -jar distribuidora-app.jar --hash <senha>");
            return;
        }
        String sal = Senha.novoSal();
        String hash = Senha.calcularHash(args[1].toCharArray(), sal);
        System.out.println("senha_sal  = " + sal);
        System.out.println("senha_hash = " + hash);
    }

    /** Mantido para o caso de ser preciso avisar antes de existir janela. */
    static void avisarSemJanela(String mensagem) {
        JOptionPane.showMessageDialog(null, mensagem);
        Aviso.erro(null, mensagem);
    }
}
