package br.ucb.distribuidora.ui;

import br.ucb.distribuidora.dao.CategoriaDAO;
import br.ucb.distribuidora.dao.ClienteDAO;
import br.ucb.distribuidora.dao.FornecedorDAO;
import br.ucb.distribuidora.dao.FuncionarioDAO;
import br.ucb.distribuidora.dao.ProdutoDAO;
import br.ucb.distribuidora.dao.UsuarioDAO;

import java.awt.BorderLayout;
import javax.swing.BorderFactory;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JTabbedPane;

/**
 * Janela principal, organizada em abas.
 *
 * O perfil do usuario autenticado decide o que aparece, que e o lado de
 * aplicacao do menor privilegio pedido no B5. O controle que vale e o do
 * banco, com GRANT e REVOKE: esconder aba so evita que a pessoa tente
 * uma operacao que o banco recusaria de qualquer jeito.
 */
public class JanelaPrincipal extends JFrame {

    private static final long serialVersionUID = 1L;

    public JanelaPrincipal(UsuarioDAO.Usuario usuario) {
        super("Distribuidora de Bebidas - " + usuario.getLogin()
              + " (" + usuario.getPerfil() + ")");

        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(1000, 680);
        setLocationRelativeTo(null);

        JTabbedPane abas = new JTabbedPane();

        // Operacao do dia a dia: disponivel para todos os perfis.
        abas.addTab("Nova venda", new PainelVenda());
        abas.addTab("Consultas", new PainelConsultas());
        abas.addTab("Relatorio", new PainelRelatorio());

        // Cadastros: estoquista nao mexe em cliente nem em funcionario.
        abas.addTab("Produtos", new PainelCadastro(new ProdutoDAO()));
        abas.addTab("Categorias", new PainelCadastro(new CategoriaDAO()));
        abas.addTab("Fornecedores", new PainelCadastro(new FornecedorDAO()));

        if (!"ESTOQUISTA".equals(usuario.getPerfil())) {
            abas.addTab("Clientes", new PainelCadastro(new ClienteDAO()));
        }
        if (usuario.ehAdmin()) {
            abas.addTab("Funcionarios", new PainelCadastro(new FuncionarioDAO()));
        }

        add(abas, BorderLayout.CENTER);

        JLabel rodape = new JLabel(
                "Projeto Final de Laboratorio de Banco de Dados - Etapa 2 - UCB 2026/2");
        rodape.setBorder(BorderFactory.createEmptyBorder(4, 10, 6, 10));
        add(rodape, BorderLayout.SOUTH);
    }
}
