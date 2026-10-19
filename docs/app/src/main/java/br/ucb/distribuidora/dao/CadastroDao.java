package br.ucb.distribuidora.dao;

import br.ucb.distribuidora.db.ErroNegocio;

import java.util.Map;

/**
 * Contrato dos quatro cadastros com CRUD completo exigidos no B1:
 * produto, cliente, fornecedor e funcionario.
 *
 * O painel de cadastro conhece apenas esta interface. Cada implementacao
 * traz o SQL da sua entidade, e e nelas que o SQL fica visivel -- o que o
 * enunciado exige para que o plano de execucao possa ser analisado no B4.
 */
public interface CadastroDao {

    /** Nome da aba, por exemplo "Produtos". */
    String titulo();

    /** Campos do formulario. Pode consultar o banco para montar combos. */
    Campo[] campos() throws ErroNegocio;

    /**
     * Linhas da tabela. A PRIMEIRA coluna precisa ser o identificador:
     * e por ela que o painel sabe qual registro foi selecionado.
     *
     * @param filtro texto digitado na busca; vazio traz tudo
     */
    Tabela listar(String filtro) throws ErroNegocio;

    /** Valores atuais de um registro, para preencher o formulario. */
    Map<String, String> carregar(int id) throws ErroNegocio;

    void inserir(Map<String, String> valores) throws ErroNegocio;

    void atualizar(int id, Map<String, String> valores) throws ErroNegocio;

    void excluir(int id) throws ErroNegocio;
}
