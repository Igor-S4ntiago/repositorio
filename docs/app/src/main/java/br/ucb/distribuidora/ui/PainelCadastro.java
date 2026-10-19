package br.ucb.distribuidora.ui;

import br.ucb.distribuidora.dao.CadastroDao;
import br.ucb.distribuidora.dao.Campo;
import br.ucb.distribuidora.dao.ConsultaDAO;
import br.ucb.distribuidora.dao.Tabela;
import br.ucb.distribuidora.db.ErroNegocio;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.event.HierarchyEvent;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSplitPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.ListSelectionModel;
import javax.swing.table.DefaultTableModel;

/**
 * Tela de cadastro com CRUD completo. Serve as quatro entidades do B1.
 *
 * O painel nao sabe se esta editando produto ou fornecedor: ele monta a
 * tabela e o formulario a partir do que o CadastroDao descreve. Assim o
 * SQL fica concentrado nas classes DAO, e a tela cuida so da interacao.
 */
public class PainelCadastro extends JPanel {

    private static final long serialVersionUID = 1L;

    private final transient CadastroDao dao;

    private final JTextField busca = new JTextField(22);
    private final DefaultTableModel modelo = new DefaultTableModel() {
        private static final long serialVersionUID = 1L;

        @Override
        public boolean isCellEditable(int linha, int coluna) {
            return false;   // a tabela so exibe; a edicao acontece no formulario
        }
    };
    private final JTable tabela = new JTable(modelo);

    private final JPanel formulario = new JPanel(new GridBagLayout());
    private final transient Map<String, JComponentValor> editores = new LinkedHashMap<>();
    private final JLabel situacao = new JLabel(" ");

    /** Registro em edicao. Null significa que um novo esta sendo criado. */
    private Integer idSelecionado;

    public PainelCadastro(CadastroDao dao) {
        super(new BorderLayout(8, 8));
        this.dao = dao;
        setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        add(montarBarraBusca(), BorderLayout.NORTH);

        JScrollPane rolagem = new JScrollPane(tabela);
        rolagem.setPreferredSize(new Dimension(640, 260));
        tabela.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        tabela.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                aoSelecionarLinha();
            }
        });

        JSplitPane divisor = new JSplitPane(
                JSplitPane.VERTICAL_SPLIT, rolagem, montarAreaFormulario());
        divisor.setResizeWeight(0.55);
        add(divisor, BorderLayout.CENTER);

        add(situacao, BorderLayout.SOUTH);

        montarCampos();
        recarregar();

        // As opcoes de um combo -- categoria em produto, supervisor em
        // funcionario -- saem do banco quando a tela e montada, e a tela
        // e montada uma vez so, no login. Sem isto, uma categoria criada
        // na aba ao lado nao apareceria aqui ate reabrir a aplicacao, que
        // e justamente a sequencia de quem esta demonstrando o sistema:
        // criar a categoria e em seguida o produto nela.
        addHierarchyListener(e -> {
            if ((e.getChangeFlags() & HierarchyEvent.SHOWING_CHANGED) != 0
                    && isShowing()) {
                recarregarListas();
            }
        });
    }

    // -----------------------------------------------------------------
    // Montagem da tela
    // -----------------------------------------------------------------

    private JPanel montarBarraBusca() {
        JPanel barra = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 2));
        barra.add(new JLabel("Buscar:"));
        barra.add(busca);

        JButton bBuscar = new JButton("Buscar");
        bBuscar.addActionListener(e -> recarregar());
        barra.add(bBuscar);

        JButton bLimpar = new JButton("Mostrar todos");
        bLimpar.addActionListener(e -> {
            busca.setText("");
            recarregar();
        });
        barra.add(bLimpar);

        busca.addActionListener(e -> recarregar());
        return barra;
    }

    private JPanel montarAreaFormulario() {
        JPanel area = new JPanel(new BorderLayout(6, 6));
        formulario.setBorder(BorderFactory.createTitledBorder("Dados do registro"));
        area.add(new JScrollPane(formulario), BorderLayout.CENTER);

        JPanel botoes = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 4));

        JButton bNovo = new JButton("Novo");
        bNovo.addActionListener(e -> limparFormulario());
        botoes.add(bNovo);

        JButton bSalvar = new JButton("Salvar");
        bSalvar.addActionListener(e -> salvar());
        botoes.add(bSalvar);

        JButton bExcluir = new JButton("Excluir");
        bExcluir.addActionListener(e -> excluir());
        botoes.add(bExcluir);

        area.add(botoes, BorderLayout.SOUTH);
        return area;
    }

    /** Cria um editor por campo descrito pelo DAO. */
    private void montarCampos() {
        try {
            GridBagConstraints c = new GridBagConstraints();
            c.insets = new Insets(4, 6, 4, 6);
            c.anchor = GridBagConstraints.WEST;
            int linha = 0;

            for (Campo campo : dao.campos()) {
                c.gridx = 0;
                c.gridy = linha;
                c.weightx = 0;
                c.fill = GridBagConstraints.NONE;
                String rotulo = campo.getRotulo() + (campo.isObrigatorio() ? " *" : "");
                formulario.add(new JLabel(rotulo), c);

                c.gridx = 1;
                c.weightx = 1;
                c.fill = GridBagConstraints.HORIZONTAL;

                JComponentValor editor;
                if (campo.getTipo() == Campo.Tipo.LISTA) {
                    JComboBox<ConsultaDAO.Opcao> combo = new JComboBox<>();
                    for (ConsultaDAO.Opcao o : campo.getOpcoes()) {
                        combo.addItem(o);
                    }
                    editor = new EditorCombo(combo);
                } else {
                    editor = new EditorTexto(new JTextField(26));
                }
                formulario.add(editor.componente(), c);
                editores.put(campo.getNome(), editor);
                linha++;
            }

            c.gridx = 0;
            c.gridy = linha;
            c.gridwidth = 2;
            formulario.add(new JLabel("Campos com * sao obrigatorios."), c);

        } catch (ErroNegocio e) {
            Aviso.erro(this, e);
        }
    }

    // -----------------------------------------------------------------
    // Acoes
    // -----------------------------------------------------------------

    /**
     * Refaz as opcoes dos combos a partir do banco, sem remontar a tela.
     *
     * Chamar dao.campos() de novo e o bastante: e esse metodo que vai ao
     * banco buscar as opcoes. O que estava escolhido e preservado, para
     * que recarregar no meio de uma edicao nao troque o valor do campo.
     */
    private void recarregarListas() {
        try {
            for (Campo campo : dao.campos()) {
                if (campo.getTipo() != Campo.Tipo.LISTA) {
                    continue;
                }
                JComponentValor editor = editores.get(campo.getNome());
                if (editor instanceof EditorCombo combo) {
                    combo.trocarOpcoes(campo.getOpcoes());
                }
            }
        } catch (ErroNegocio e) {
            Aviso.erro(this, e);
        }
    }

    private void recarregar() {
        try {
            Tabela t = dao.listar(busca.getText());
            modelo.setDataVector(t.getLinhas(), t.getColunas());
            situacao.setText(t.getQuantidadeLinhas() + " registro(s) encontrado(s).");
            limparFormulario();
        } catch (ErroNegocio e) {
            Aviso.erro(this, e);
        }
    }

    private void aoSelecionarLinha() {
        int linha = tabela.getSelectedRow();
        if (linha < 0) {
            return;
        }
        Object id = modelo.getValueAt(linha, 0);   // 1a coluna = identificador
        try {
            idSelecionado = Integer.valueOf(String.valueOf(id));
            Map<String, String> valores = dao.carregar(idSelecionado);
            for (Map.Entry<String, JComponentValor> par : editores.entrySet()) {
                par.getValue().definir(valores.getOrDefault(par.getKey(), ""));
            }
            situacao.setText("Editando o registro " + idSelecionado + ".");
        } catch (NumberFormatException e) {
            Aviso.erro(this, "A primeira coluna da listagem precisa ser o identificador.");
        } catch (ErroNegocio e) {
            Aviso.erro(this, e);
        }
    }

    private void limparFormulario() {
        idSelecionado = null;
        for (JComponentValor editor : editores.values()) {
            editor.definir("");
        }
        tabela.clearSelection();
        situacao.setText("Preenchendo um registro novo.");
    }

    private void salvar() {
        Map<String, String> valores = new LinkedHashMap<>();
        for (Map.Entry<String, JComponentValor> par : editores.entrySet()) {
            valores.put(par.getKey(), par.getValue().ler());
        }

        try {
            for (Campo campo : dao.campos()) {
                String v = valores.get(campo.getNome());
                if (campo.isObrigatorio() && (v == null || v.isBlank())) {
                    Aviso.erro(this, "Preencha o campo " + campo.getRotulo() + ".");
                    return;
                }
            }

            if (idSelecionado == null) {
                dao.inserir(valores);
                Aviso.sucesso(this, "Registro criado.");
            } else {
                dao.atualizar(idSelecionado, valores);
                Aviso.sucesso(this, "Registro atualizado.");
            }
            recarregar();

        } catch (ErroNegocio e) {
            // Aqui chega, por exemplo, "Ja existe uma pessoa cadastrada
            // com esse CPF" -- a restricao uq_pessoa_cpf traduzida.
            Aviso.erro(this, e);
        }
    }

    private void excluir() {
        if (idSelecionado == null) {
            Aviso.erro(this, "Selecione na tabela o registro que deseja excluir.");
            return;
        }
        if (!Aviso.confirma(this, "Excluir o registro " + idSelecionado + "?")) {
            return;
        }
        try {
            dao.excluir(idSelecionado);
            Aviso.sucesso(this, "Registro excluido.");
            recarregar();
        } catch (ErroNegocio e) {
            // Produto ja vendido, cliente com pedidos: o banco recusa pela
            // chave estrangeira RESTRICT e a recusa aparece aqui.
            Aviso.erro(this, e);
        }
    }

    // -----------------------------------------------------------------
    // Editores: caixa de texto ou combo, com a mesma interface
    // -----------------------------------------------------------------

    private interface JComponentValor {
        java.awt.Component componente();

        String ler();

        void definir(String valor);
    }

    private static class EditorTexto implements JComponentValor {
        private final JTextField campo;

        EditorTexto(JTextField campo) {
            this.campo = campo;
        }

        @Override
        public java.awt.Component componente() {
            return campo;
        }

        @Override
        public String ler() {
            return campo.getText().trim();
        }

        @Override
        public void definir(String valor) {
            campo.setText(valor);
        }
    }

    private static class EditorCombo implements JComponentValor {
        private final JComboBox<ConsultaDAO.Opcao> combo;

        EditorCombo(JComboBox<ConsultaDAO.Opcao> combo) {
            this.combo = combo;
        }

        @Override
        public java.awt.Component componente() {
            return combo;
        }

        /** Troca as opcoes mantendo a escolha atual, se ela ainda existir. */
        void trocarOpcoes(List<ConsultaDAO.Opcao> novas) {
            String escolhido = ler();
            combo.removeAllItems();
            for (ConsultaDAO.Opcao o : novas) {
                combo.addItem(o);
            }
            definir(escolhido);
        }

        @Override
        public String ler() {
            ConsultaDAO.Opcao o = (ConsultaDAO.Opcao) combo.getSelectedItem();
            return o == null ? "" : String.valueOf(o.getId());
        }

        @Override
        public void definir(String valor) {
            if (valor == null || valor.isBlank()) {
                if (combo.getItemCount() > 0) {
                    combo.setSelectedIndex(0);
                }
                return;
            }
            int procurado = Integer.parseInt(valor);
            for (int i = 0; i < combo.getItemCount(); i++) {
                if (combo.getItemAt(i).getId() == procurado) {
                    combo.setSelectedIndex(i);
                    return;
                }
            }
        }
    }
}
