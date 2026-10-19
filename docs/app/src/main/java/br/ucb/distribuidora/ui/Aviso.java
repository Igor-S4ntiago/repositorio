package br.ucb.distribuidora.ui;

import br.ucb.distribuidora.db.ErroNegocio;

import java.awt.Component;
import javax.swing.JOptionPane;

/**
 * Caixas de mensagem da aplicacao.
 *
 * Existe para que o B1 seja cumprido em um lugar so: quando o banco
 * recusa uma operacao, o usuario ve a frase traduzida pelo TradutorErro,
 * e nunca o texto cru da excecao do driver.
 */
public class Aviso {

    private Aviso() {
    }

    /** Mostra a mensagem amigavel do erro. */
    public static void erro(Component pai, ErroNegocio e) {
        JOptionPane.showMessageDialog(
                pai, e.getMessage(), "Nao foi possivel concluir",
                JOptionPane.WARNING_MESSAGE);
    }

    public static void erro(Component pai, String mensagem) {
        JOptionPane.showMessageDialog(
                pai, mensagem, "Nao foi possivel concluir",
                JOptionPane.WARNING_MESSAGE);
    }

    public static void sucesso(Component pai, String mensagem) {
        JOptionPane.showMessageDialog(
                pai, mensagem, "Pronto", JOptionPane.INFORMATION_MESSAGE);
    }

    public static boolean confirma(Component pai, String pergunta) {
        int r = JOptionPane.showConfirmDialog(
                pai, pergunta, "Confirmar", JOptionPane.YES_NO_OPTION,
                JOptionPane.QUESTION_MESSAGE);
        return r == JOptionPane.YES_OPTION;
    }
}
