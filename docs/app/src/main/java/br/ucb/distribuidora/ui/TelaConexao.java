package br.ucb.distribuidora.ui;

import br.ucb.distribuidora.db.Conexao;
import br.ucb.distribuidora.db.ErroNegocio;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Cursor;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.util.Properties;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JPasswordField;
import javax.swing.JTextField;

/**
 * Pede os dados de acesso ao banco quando ainda nao ha config.properties,
 * ou quando o que existe nao conecta.
 *
 * A razao de existir e pratica: a aplicacao precisa rodar em maquinas
 * diferentes, e a senha do MySQL muda de uma para outra. Sem esta tela, a
 * alternativa seria abrir o config.properties num editor e digitar a
 * senha ali -- o que funciona, mas e um passo a mais e um lugar a mais
 * para errar. Aqui o usuario digita, clica em Testar, e so segue adiante
 * quando o banco respondeu de fato.
 *
 * O botao Testar e o ponto importante. Ele conecta antes de salvar, de
 * modo que um erro de senha aparece aqui, com a causa na tela, e nao
 * depois, no meio de uma operacao.
 *
 * As credenciais continuam fora do codigo-fonte: o que esta tela faz e
 * gravar o mesmo config.properties que o config.properties.exemplo
 * documenta, e que o .gitignore mantem fora do repositorio.
 */
public class TelaConexao extends JDialog {

    private static final long serialVersionUID = 1L;

    private final JTextField campoServidor = new JTextField("localhost", 18);
    private final JTextField campoPorta = new JTextField("3306", 18);
    private final JTextField campoBanco =
            new JTextField("distribuidora_bebidas", 18);
    private final JTextField campoUsuario = new JTextField("root", 18);
    private final JPasswordField campoSenha = new JPasswordField(18);

    private final JLabel recado = new JLabel(" ");

    /** Fica preenchido quando o teste passou. Null quando desistiu. */
    private transient Properties aprovada;

    private TelaConexao() {
        super((java.awt.Frame) null, "Conexao com o banco de dados", true);
        setDefaultCloseOperation(DISPOSE_ON_CLOSE);

        JPanel corpo = new JPanel(new GridBagLayout());
        corpo.setBorder(BorderFactory.createEmptyBorder(16, 16, 10, 16));

        GridBagConstraints c = new GridBagConstraints();
        c.insets = new Insets(4, 5, 4, 5);
        c.anchor = GridBagConstraints.WEST;

        c.gridx = 0;
        c.gridy = 0;
        c.gridwidth = 2;
        corpo.add(new JLabel("Informe o acesso ao MySQL desta maquina."), c);
        c.gridwidth = 1;

        int linha = 1;
        linha = adicionar(corpo, c, linha, "Servidor:", campoServidor);
        linha = adicionar(corpo, c, linha, "Porta:", campoPorta);
        linha = adicionar(corpo, c, linha, "Banco:", campoBanco);
        linha = adicionar(corpo, c, linha, "Usuario:", campoUsuario);
        linha = adicionar(corpo, c, linha, "Senha:", campoSenha);

        c.gridx = 0;
        c.gridy = linha;
        c.gridwidth = 2;
        corpo.add(recado, c);

        JPanel botoes = new JPanel();
        JButton bTestar = new JButton("Testar e continuar");
        bTestar.addActionListener(e -> testar());
        botoes.add(bTestar);

        JButton bSair = new JButton("Sair");
        bSair.addActionListener(e -> dispose());
        botoes.add(bSair);

        getRootPane().setDefaultButton(bTestar);
        campoSenha.addActionListener(e -> testar());

        add(corpo, BorderLayout.CENTER);
        add(botoes, BorderLayout.SOUTH);

        pack();
        setLocationRelativeTo(null);
    }

    private int adicionar(JPanel painel, GridBagConstraints c, int linha,
                          String rotulo, javax.swing.JComponent campo) {
        c.gridx = 0;
        c.gridy = linha;
        painel.add(new JLabel(rotulo), c);
        c.gridx = 1;
        painel.add(campo, c);
        return linha + 1;
    }

    private void testar() {
        Properties candidata = new Properties();
        candidata.setProperty("db.url", Conexao.montarUrl(
                campoServidor.getText().trim(),
                campoPorta.getText().trim(),
                campoBanco.getText().trim()));
        candidata.setProperty("db.usuario", campoUsuario.getText().trim());
        candidata.setProperty("db.senha", new String(campoSenha.getPassword()));

        recado.setForeground(Color.DARK_GRAY);
        recado.setText("Testando...");
        setCursor(Cursor.getPredefinedCursor(Cursor.WAIT_CURSOR));

        // O teste e rapido o bastante para rodar na propria thread da
        // interface. Se um dia passar a travar a janela, o caminho e
        // mover isto para um SwingWorker.
        String erro = Conexao.testar(candidata);

        setCursor(Cursor.getDefaultCursor());

        if (erro != null) {
            recado.setForeground(Color.RED.darker());
            recado.setText(resumir(erro));
            return;
        }

        aprovada = candidata;
        Conexao.definir(candidata);

        // Gravar e comodidade, nao requisito: se a pasta for somente
        // leitura, a aplicacao segue funcionando nesta execucao.
        try {
            Conexao.salvar(candidata);
        } catch (ErroNegocio e) {
            Aviso.erro(this, e);
        }

        dispose();
    }

    /**
     * A mensagem do driver costuma ser longa e tecnica. Aqui ela vira uma
     * frase curta, com a causa provavel, para caber na tela e dizer o que
     * fazer. O texto original continua no erro, caso seja preciso.
     */
    private String resumir(String bruto) {
        String m = bruto.toLowerCase();

        if (m.contains("access denied")) {
            return "Usuario ou senha incorretos.";
        }
        if (m.contains("unknown database")) {
            return "O banco nao existe. Importe o banco-completo.sql primeiro.";
        }
        if (m.contains("communications link failure")
                || m.contains("connection refused")) {
            return "O MySQL nao respondeu. Confira se o servico esta no ar.";
        }
        if (m.contains("public key retrieval")) {
            return "Falta allowPublicKeyRetrieval na URL. Reporte este erro.";
        }
        if (m.contains("no suitable driver")) {
            return "O driver do MySQL nao esta no classpath.";
        }
        return bruto.length() > 90 ? bruto.substring(0, 90) + "..." : bruto;
    }

    /**
     * Abre a tela e devolve se a conexao ficou resolvida.
     *
     * @return true quando o teste passou, false quando o usuario desistiu
     */
    public static boolean configurar() {
        TelaConexao tela = new TelaConexao();
        tela.setVisible(true);          // bloqueia ate fechar
        return tela.aprovada != null;
    }
}
