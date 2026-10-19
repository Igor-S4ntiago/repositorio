package br.ucb.distribuidora.ui;

import br.ucb.distribuidora.dao.ConsultaDAO;
import br.ucb.distribuidora.dao.ItemVenda;
import br.ucb.distribuidora.dao.VendaDAO;
import br.ucb.distribuidora.db.ErroNegocio;

import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.event.HierarchyEvent;
import java.util.ArrayList;
import java.util.List;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSpinner;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.SpinnerNumberModel;
import javax.swing.table.DefaultTableModel;

/**
 * Tela da operacao transacional: registrar uma venda.
 *
 * E o item central da Etapa 2. A tela monta a lista de itens em memoria e
 * chama o VendaDAO uma unica vez; e o DAO que abre a transacao, toca as
 * cinco tabelas e decide entre COMMIT e ROLLBACK.
 *
 * A caixa "provocar falha" existe para a demonstracao exigida no B3:
 * com ela marcada, a transacao executa todos os passos e so entao falha,
 * de modo que da para mostrar na tela seguinte que nada foi gravado.
 */
public class PainelVenda extends JPanel {

    private static final long serialVersionUID = 1L;

    private final transient ConsultaDAO consultas = new ConsultaDAO();
    private final transient VendaDAO vendas = new VendaDAO();

    private final JComboBox<ConsultaDAO.Opcao> comboCliente = new JComboBox<>();
    private final JComboBox<ConsultaDAO.Opcao> comboProduto = new JComboBox<>();
    private final JTextField filtroProduto = new JTextField(16);
    private final JSpinner quantidade = new JSpinner(new SpinnerNumberModel(1, 1, 9999, 1));
    private final JComboBox<String> comboPagamento = new JComboBox<>(new String[] {
        "PIX", "Boleto Bancario", "Cartao de Credito", "Cartao de Debito",
        "Dinheiro", "Transferencia Bancaria"
    });
    private final JCheckBox provocarFalha = new JCheckBox(
            "Provocar falha no fim da transacao (demonstracao do rollback)");

    private final DefaultTableModel modeloItens = new DefaultTableModel(
            new String[] { "Produto", "Quantidade" }, 0) {
        private static final long serialVersionUID = 1L;

        @Override
        public boolean isCellEditable(int l, int c) {
            return false;
        }
    };
    private final JTable tabelaItens = new JTable(modeloItens);

    /** Itens montados na tela, ainda fora do banco. */
    private final transient List<ItemVenda> itens = new ArrayList<>();

    public PainelVenda() {
        super(new BorderLayout(8, 8));
        setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        add(montarTopo(), BorderLayout.NORTH);

        JScrollPane rolagem = new JScrollPane(tabelaItens);
        rolagem.setBorder(BorderFactory.createTitledBorder("Itens da venda"));
        add(rolagem, BorderLayout.CENTER);

        add(montarRodape(), BorderLayout.SOUTH);

        carregarCombos();

        // Cliente e produto podem ser criados nas abas de cadastro depois
        // que esta tela ja existe. Sem recarregar ao voltar para ca, o
        // cadastro recem-feito nao estaria disponivel para vender, e a
        // tela estaria mostrando saldos de estoque defasados -- o que e
        // pior, porque saldo errado na tela de venda nao parece erro.
        addHierarchyListener(e -> {
            if ((e.getChangeFlags() & HierarchyEvent.SHOWING_CHANGED) != 0
                    && isShowing()) {
                carregarCombos();
            }
        });
    }

    private JPanel montarTopo() {
        JPanel topo = new JPanel(new java.awt.GridLayout(3, 1, 4, 4));

        JPanel l1 = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 2));
        l1.add(new JLabel("Cliente:"));
        comboCliente.setPreferredSize(new java.awt.Dimension(320, 26));
        l1.add(comboCliente);
        l1.add(new JLabel("     Forma de pagamento:"));
        l1.add(comboPagamento);
        topo.add(l1);

        JPanel l2 = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 2));
        l2.add(new JLabel("Filtrar produto:"));
        l2.add(filtroProduto);
        JButton bFiltrar = new JButton("Filtrar");
        bFiltrar.addActionListener(e -> carregarProdutos());
        l2.add(bFiltrar);
        filtroProduto.addActionListener(e -> carregarProdutos());
        topo.add(l2);

        JPanel l3 = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 2));
        l3.add(new JLabel("Produto:"));
        comboProduto.setPreferredSize(new java.awt.Dimension(380, 26));
        l3.add(comboProduto);
        l3.add(new JLabel("Qtd:"));
        l3.add(quantidade);
        JButton bIncluir = new JButton("Incluir item");
        bIncluir.addActionListener(e -> incluirItem());
        l3.add(bIncluir);
        JButton bRemover = new JButton("Remover selecionado");
        bRemover.addActionListener(e -> removerItem());
        l3.add(bRemover);
        topo.add(l3);

        return topo;
    }

    private JPanel montarRodape() {
        JPanel rodape = new JPanel(new java.awt.GridLayout(2, 1, 4, 4));

        JPanel l1 = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 2));
        l1.add(provocarFalha);
        rodape.add(l1);

        JPanel l2 = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 2));
        JButton bGravar = new JButton("Registrar venda");
        bGravar.addActionListener(e -> registrar());
        l2.add(bGravar);
        JButton bLimpar = new JButton("Limpar");
        bLimpar.addActionListener(e -> {
            itens.clear();
            modeloItens.setRowCount(0);
        });
        l2.add(bLimpar);
        rodape.add(l2);

        return rodape;
    }

    private void carregarCombos() {
        try {
            int escolhido = idEscolhido(comboCliente);
            comboCliente.removeAllItems();
            for (ConsultaDAO.Opcao o : consultas.listarClientes()) {
                comboCliente.addItem(o);
            }
            escolher(comboCliente, escolhido);

            carregarProdutos();
        } catch (ErroNegocio e) {
            Aviso.erro(this, e);
        }
    }

    /** Id do item escolhido, ou -1 quando nao ha escolha. */
    private int idEscolhido(JComboBox<ConsultaDAO.Opcao> combo) {
        ConsultaDAO.Opcao o = (ConsultaDAO.Opcao) combo.getSelectedItem();
        return o == null ? -1 : o.getId();
    }

    /**
     * Devolve a escolha ao combo depois de refazer a lista.
     *
     * Sem isto, trocar de aba no meio de uma venda limparia o cliente e o
     * produto ja escolhidos, enquanto os itens incluidos continuariam na
     * tabela -- a tela pareceria ter perdido o que o usuario fez.
     */
    private void escolher(JComboBox<ConsultaDAO.Opcao> combo, int id) {
        for (int i = 0; i < combo.getItemCount(); i++) {
            if (combo.getItemAt(i).getId() == id) {
                combo.setSelectedIndex(i);
                return;
            }
        }
    }

    /**
     * Recarrega o combo de produtos aplicando o filtro digitado.
     *
     * O filtro vai como parametro do PreparedStatement. E esta tela que
     * serve de demonstracao de resistencia a injecao no relatorio: ao
     * digitar  ' OR '1'='1  o combo fica vazio, porque o texto e
     * procurado como nome de produto, e nao executado como comando.
     */
    private void carregarProdutos() {
        try {
            int escolhido = idEscolhido(comboProduto);
            comboProduto.removeAllItems();
            String filtro = filtroProduto.getText().trim();
            List<ConsultaDAO.Opcao> achados = consultas.listarProdutosComSaldo(filtro);
            for (ConsultaDAO.Opcao o : achados) {
                comboProduto.addItem(o);
            }
            escolher(comboProduto, escolhido);
            if (achados.isEmpty()) {
                // Lista vazia significa coisas diferentes conforme haja ou
                // nao filtro. Sem filtro, nao foi o filtro que nao achou
                // nada: o banco e que esta sem dados, e dizer "nenhum
                // produto corresponde ao filtro informado" quando nenhum
                // filtro foi informado manda procurar no lugar errado.
                Aviso.erro(this, filtro.isEmpty()
                        ? "Nao ha produtos com posicao de estoque cadastrada.\n"
                          + "Confira se o 02_carga.sql foi executado no banco."
                        : "Nenhum produto corresponde ao filtro informado.");
            }
        } catch (ErroNegocio e) {
            Aviso.erro(this, e);
        }
    }

    private void incluirItem() {
        ConsultaDAO.Opcao produto = (ConsultaDAO.Opcao) comboProduto.getSelectedItem();
        if (produto == null) {
            Aviso.erro(this, "Escolha um produto.");
            return;
        }
        int qtd = (Integer) quantidade.getValue();

        for (ItemVenda ja : itens) {
            if (ja.getIdProduto() == produto.getId()) {
                // RN18: o mesmo produto nao se repete no mesmo pedido.
                Aviso.erro(this, "Esse produto ja esta na venda (RN18).\n"
                        + "Remova o item e inclua de novo com a quantidade certa.");
                return;
            }
        }

        itens.add(new ItemVenda(produto.getId(), produto.toString(), qtd));
        modeloItens.addRow(new Object[] { produto.toString(), qtd });
    }

    private void removerItem() {
        int linha = tabelaItens.getSelectedRow();
        if (linha < 0) {
            Aviso.erro(this, "Selecione o item que deseja remover.");
            return;
        }
        itens.remove(linha);
        modeloItens.removeRow(linha);
    }

    private void registrar() {
        ConsultaDAO.Opcao cliente = (ConsultaDAO.Opcao) comboCliente.getSelectedItem();
        if (cliente == null) {
            Aviso.erro(this, "Escolha o cliente.");
            return;
        }

        try {
            int idPedido = vendas.registrarVenda(
                    cliente.getId(),
                    String.valueOf(comboPagamento.getSelectedItem()),
                    itens,
                    provocarFalha.isSelected());

            Aviso.sucesso(this,
                    "Venda registrada. Numero do pedido: " + idPedido + "\n\n"
                    + "Em uma unica transacao foram gravados o pedido, os itens, "
                    + "a baixa de estoque, a movimentacao e o pagamento pendente.");

            itens.clear();
            modeloItens.setRowCount(0);
            carregarProdutos();   // atualiza os saldos mostrados no combo

        } catch (ErroNegocio e) {
            // Chega aqui tanto a falta de estoque quanto a falha provocada.
            // Em ambos os casos o ROLLBACK ja aconteceu dentro do DAO.
            Aviso.erro(this, e);
            carregarProdutos();
        }
    }
}
