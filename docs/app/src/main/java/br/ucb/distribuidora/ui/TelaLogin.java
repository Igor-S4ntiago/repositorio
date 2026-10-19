package br.ucb.distribuidora.ui;

import br.ucb.distribuidora.dao.UsuarioDAO;
import br.ucb.distribuidora.db.ErroNegocio;

import java.awt.BorderLayout;
import java.awt.Frame;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JPasswordField;
import javax.swing.JTextField;

/**
 * Tela de login.
 *
 * A senha fica em JPasswordField e viaja como char[] ate o UsuarioDAO,
 * que a apaga da memoria assim que termina de conferir. Em nenhum momento
 * ela vira String, porque String em Java e imutavel: nao da para limpar
 * depois, e ela ficaria na memoria ate o coletor de lixo passar.
 */
public class TelaLogin extends JDialog {

    private static final long serialVersionUID = 1L;

    private final JTextField campoLogin = new JTextField(18);
    private final JPasswordField campoSenha = new JPasswordField(18);
    private final transient UsuarioDAO dao = new UsuarioDAO();

    private transient UsuarioDAO.Usuario autenticado;

    public TelaLogin(Frame pai) {
        super(pai, "Entrar no sistema", true);
        setDefaultCloseOperation(DISPOSE_ON_CLOSE);

        JPanel corpo = new JPanel(new GridBagLayout());
        corpo.setBorder(BorderFactory.createEmptyBorder(16, 16, 10, 16));

        GridBagConstraints c = new GridBagConstraints();
        c.insets = new Insets(5, 5, 5, 5);
        c.anchor = GridBagConstraints.WEST;

        c.gridx = 0;
        c.gridy = 0;
        corpo.add(new JLabel("Distribuidora de Bebidas"), c);

        c.gridy = 1;
        corpo.add(new JLabel("Login:"), c);
        c.gridx = 1;
        corpo.add(campoLogin, c);

        c.gridx = 0;
        c.gridy = 2;
        corpo.add(new JLabel("Senha:"), c);
        c.gridx = 1;
        corpo.add(campoSenha, c);

        JPanel botoes = new JPanel();
        JButton bEntrar = new JButton("Entrar");
        bEntrar.addActionListener(e -> entrar());
        botoes.add(bEntrar);

        JButton bSair = new JButton("Sair");
        bSair.addActionListener(e -> dispose());
        botoes.add(bSair);

        getRootPane().setDefaultButton(bEntrar);
        campoSenha.addActionListener(e -> entrar());

        add(corpo, BorderLayout.CENTER);
        add(botoes, BorderLayout.SOUTH);

        pack();
        setLocationRelativeTo(pai);
    }

    private void entrar() {
        String login = campoLogin.getText().trim();
        if (login.isEmpty()) {
            Aviso.erro(this, "Informe o login.");
            return;
        }
        try {
            UsuarioDAO.Usuario u = dao.autenticar(login, campoSenha.getPassword());
            if (u == null) {
                // Mensagem unica de proposito: dizer "usuario nao existe"
                // entregaria quais logins sao validos.
                Aviso.erro(this, "Login ou senha incorretos.");
                campoSenha.setText("");
                return;
            }
            autenticado = u;
            dispose();
        } catch (ErroNegocio e) {
            Aviso.erro(this, e);
        }
    }

    /** Null quando a janela foi fechada sem autenticar. */
    public UsuarioDAO.Usuario getAutenticado() {
        return autenticado;
    }
}
