package br.ucb.distribuidora.ui;

import br.ucb.distribuidora.dao.ConsultaDAO;
import br.ucb.distribuidora.dao.Tabela;
import br.ucb.distribuidora.db.ErroNegocio;

import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.math.BigDecimal;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.table.DefaultTableModel;

/**
 * Relatorio consolidado alimentado por visao, como pede o B1.
 *
 * A tela nao tem regra de apuracao nenhuma: ela faz um SELECT na visao
 * vw_faturamento_categoria, criada no 04_etapa2.sql. Quem decide o que
 * entra no faturamento -- inclusive excluir os pedidos cancelados pela
 * RN19 -- e o banco, nao o Java.
 */
public class PainelRelatorio extends JPanel {

    private static final long serialVersionUID = 1L;

    private final transient ConsultaDAO dao = new ConsultaDAO();

    private final DefaultTableModel modelo = new DefaultTableModel() {
        private static final long serialVersionUID = 1L;

        @Override
        public boolean isCellEditable(int l, int c) {
            return false;
        }
    };
    private final JTable tabela = new JTable(modelo);
    private final JLabel total = new JLabel(" ");

    public PainelRelatorio() {
        super(new BorderLayout(8, 8));
        setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        JPanel topo = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 2));
        topo.add(new JLabel("Fonte: visao vw_faturamento_categoria"));
        JButton b = new JButton("Atualizar");
        b.addActionListener(e -> carregar());
        topo.add(b);
        add(topo, BorderLayout.NORTH);

        add(new JScrollPane(tabela), BorderLayout.CENTER);
        add(total, BorderLayout.SOUTH);

        carregar();
    }

    private void carregar() {
        try {
            Tabela t = dao.relatorioFaturamento();
            modelo.setDataVector(t.getLinhas(), t.getColunas());

            BigDecimal soma = BigDecimal.ZERO;
            for (Object[] linha : t.getLinhas()) {
                Object valor = linha[linha.length - 1];   // ultima coluna: faturamento
                if (valor != null) {
                    try {
                        soma = soma.add(new BigDecimal(valor.toString()));
                    } catch (NumberFormatException naoEhNumero) {
                        // coluna de texto na ultima posicao: nao entra no total
                    }
                }
            }
            total.setText("Total geral: R$ " + soma.toPlainString()
                    + "    |    " + t.getQuantidadeLinhas() + " categoria(s)");

        } catch (ErroNegocio e) {
            Aviso.erro(this, e);
        }
    }
}
