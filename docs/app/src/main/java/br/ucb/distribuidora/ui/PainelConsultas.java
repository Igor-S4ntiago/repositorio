package br.ucb.distribuidora.ui;

import br.ucb.distribuidora.dao.ConsultaDAO;
import br.ucb.distribuidora.dao.Tabela;
import br.ucb.distribuidora.db.ErroNegocio;

import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.time.LocalDate;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSpinner;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.SpinnerNumberModel;
import javax.swing.table.DefaultTableModel;

/**
 * As duas telas de consulta parametrizada do B1.
 *
 * Em cada uma, o usuario informa filtros e a aplicacao devolve o
 * resultado de uma consulta com juncao e agregacao. Nenhum filtro e
 * concatenado no SQL: todos entram como parametro.
 */
public class PainelConsultas extends JPanel {

    private static final long serialVersionUID = 1L;

    private final transient ConsultaDAO dao = new ConsultaDAO();

    // --- consulta 1: faturamento por categoria no periodo -------------
    private final JTextField de = new JTextField(10);
    private final JTextField ate = new JTextField(10);
    private final JTextField categoria = new JTextField(14);
    private final DefaultTableModel m1 = somenteLeitura();
    private final JTable t1 = new JTable(m1);
    private final JLabel r1 = new JLabel(" ");

    // --- consulta 2: produtos a recomprar -----------------------------
    private final JSpinner folga = new JSpinner(new SpinnerNumberModel(15, 0, 180, 1));
    private final DefaultTableModel m2 = somenteLeitura();
    private final JTable t2 = new JTable(m2);
    private final JLabel r2 = new JLabel(" ");

    public PainelConsultas() {
        super(new java.awt.GridLayout(2, 1, 8, 8));
        setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        de.setText(LocalDate.now().minusYears(1).toString());
        ate.setText(LocalDate.now().toString());

        add(montarFaturamento());
        add(montarRecompra());
    }

    private static DefaultTableModel somenteLeitura() {
        return new DefaultTableModel() {
            private static final long serialVersionUID = 1L;

            @Override
            public boolean isCellEditable(int l, int c) {
                return false;
            }
        };
    }

    private JPanel montarFaturamento() {
        JPanel p = new JPanel(new BorderLayout(6, 6));
        p.setBorder(BorderFactory.createTitledBorder(
                "Consulta 1 - Faturamento por categoria no periodo"));

        JPanel filtros = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 2));
        filtros.add(new JLabel("De (aaaa-mm-dd):"));
        filtros.add(de);
        filtros.add(new JLabel("Ate:"));
        filtros.add(ate);
        filtros.add(new JLabel("Categoria contem:"));
        filtros.add(categoria);

        JButton b = new JButton("Consultar");
        b.addActionListener(e -> consultarFaturamento());
        filtros.add(b);

        p.add(filtros, BorderLayout.NORTH);
        p.add(new JScrollPane(t1), BorderLayout.CENTER);
        p.add(r1, BorderLayout.SOUTH);
        return p;
    }

    private JPanel montarRecompra() {
        JPanel p = new JPanel(new BorderLayout(6, 6));
        p.setBorder(BorderFactory.createTitledBorder(
                "Consulta 2 - Produtos a recomprar (estoque nao cobre o prazo do fornecedor)"));

        JPanel filtros = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 2));
        filtros.add(new JLabel("Folga de seguranca, em dias:"));
        filtros.add(folga);

        JButton b = new JButton("Consultar");
        b.addActionListener(e -> consultarRecompra());
        filtros.add(b);

        p.add(filtros, BorderLayout.NORTH);
        p.add(new JScrollPane(t2), BorderLayout.CENTER);
        p.add(r2, BorderLayout.SOUTH);
        return p;
    }

    private void consultarFaturamento() {
        try {
            Tabela t = dao.faturamentoPorCategoria(
                    de.getText().trim(), ate.getText().trim(), categoria.getText());
            m1.setDataVector(t.getLinhas(), t.getColunas());
            r1.setText(t.getQuantidadeLinhas() + " categoria(s). "
                    + "Pedidos cancelados ficam de fora (RN19).");
        } catch (ErroNegocio e) {
            Aviso.erro(this, e);
        }
    }

    private void consultarRecompra() {
        try {
            Tabela t = dao.produtosParaRecomprar((Integer) folga.getValue());
            m2.setDataVector(t.getLinhas(), t.getColunas());
            r2.setText(t.getQuantidadeLinhas() + " produto(s) abaixo do ponto de recompra.");
        } catch (ErroNegocio e) {
            Aviso.erro(this, e);
        }
    }
}
