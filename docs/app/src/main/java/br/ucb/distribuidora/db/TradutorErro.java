package br.ucb.distribuidora.db;

import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Transforma a excecao do driver MySQL em uma frase que o usuario entende.
 *
 * Toda restricao do 01_ddl.sql recebeu nome (pk_, uq_, fk_, ck_). O driver
 * devolve esse nome dentro da mensagem de erro, e e por ele que
 * identificamos qual regra de negocio foi violada. Por isso nomear as
 * restricoes nao foi so capricho de padronizacao: e o que permite dar uma
 * resposta especifica em vez de "erro no banco de dados".
 */
public class TradutorErro {

    /**
     * Nome da restricao -> mensagem para o usuario. A ordem importa pouco,
     * mas manter agrupado por tabela ajuda a achar.
     */
    private static final Map<String, String> MENSAGENS = new LinkedHashMap<>();

    static {
        // --- unicidade -------------------------------------------------
        MENSAGENS.put("uq_pessoa_cpf",
                "Ja existe uma pessoa cadastrada com esse CPF.");
        MENSAGENS.put("uq_pessoa_email",
                "Esse e-mail ja esta em uso por outra pessoa.");
        MENSAGENS.put("uq_categoria_nome",
                "Ja existe uma categoria com esse nome.");
        MENSAGENS.put("uq_fornecedor_cnpj",
                "Ja existe um fornecedor cadastrado com esse CNPJ.");
        MENSAGENS.put("uq_fornecedor_email",
                "Esse e-mail ja esta em uso por outro fornecedor.");
        MENSAGENS.put("uq_estoque_produto",
                "Esse produto ja tem uma posicao de estoque cadastrada.");
        MENSAGENS.put("uq_pagamento_pedido",
                "Esse pedido ja possui um pagamento registrado.");
        MENSAGENS.put("uq_entrega_pedido",
                "Esse pedido ja possui uma entrega registrada.");
        MENSAGENS.put("uq_usuario_login",
                "Esse login ja esta em uso.");

        // --- verificacao de dominio ------------------------------------
        MENSAGENS.put("ck_estoque_quantidade",
                "Estoque insuficiente: a operacao deixaria o saldo negativo (RN11).");
        MENSAGENS.put("ck_item_pedido_quantidade",
                "A quantidade do item precisa ser maior que zero.");
        MENSAGENS.put("ck_item_pedido_preco",
                "O preco do item nao pode ser negativo.");
        MENSAGENS.put("ck_produto_preco_venda",
                "O preco de venda nao pode ser negativo.");
        MENSAGENS.put("ck_produto_fornecedor_preco",
                "O preco de compra nao pode ser negativo.");
        MENSAGENS.put("ck_produto_fornecedor_prazo",
                "O prazo de fornecimento nao pode ser negativo.");
        MENSAGENS.put("ck_pedido_status",
                "Situacao de pedido invalida. Use ABERTO, PAGO, ENVIADO ou CANCELADO.");
        MENSAGENS.put("ck_pagamento_status",
                "Situacao de pagamento invalida. Use PENDENTE, APROVADO ou RECUSADO.");
        MENSAGENS.put("ck_entrega_status",
                "Situacao de entrega invalida. Use PENDENTE, EM_ROTA ou ENTREGUE.");
        MENSAGENS.put("ck_movimentacao_tipo",
                "Tipo de movimentacao invalido. Use ENTRADA ou SAIDA.");
        MENSAGENS.put("ck_movimentacao_quantidade",
                "A quantidade movimentada precisa ser maior que zero.");
        MENSAGENS.put("ck_funcionario_ativo",
                "A situacao do funcionario precisa ser ativo ou inativo.");
        MENSAGENS.put("ck_usuario_perfil",
                "Perfil invalido. Use ADMIN, VENDEDOR ou ESTOQUISTA.");

        // --- integridade referencial -----------------------------------
        MENSAGENS.put("fk_produto_categoria",
                "Categoria inexistente, ou ha produtos usando essa categoria (RN04).");
        MENSAGENS.put("fk_pedido_cliente",
                "Cliente inexistente, ou o cliente ja tem pedidos e nao pode ser excluido.");
        MENSAGENS.put("fk_item_pedido_produto",
                "Produto inexistente, ou o produto ja foi vendido e nao pode ser excluido.");
        MENSAGENS.put("fk_estoque_produto",
                "Produto inexistente, ou ele ainda tem posicao de estoque.");
        MENSAGENS.put("fk_funcionario_supervisor",
                "Supervisor inexistente.");
        MENSAGENS.put("fk_entrega_funcionario",
                "Funcionario inexistente.");
    }

    private TradutorErro() {
    }

    /**
     * Devolve a frase correspondente a excecao recebida.
     *
     * @param e excecao vinda do driver
     * @param acaoEmCurso descricao curta do que o usuario tentava fazer,
     *                    por exemplo "salvar o produto"
     */
    public static String traduzir(SQLException e, String acaoEmCurso) {
        String bruta = e.getMessage() == null ? "" : e.getMessage().toLowerCase();

        for (Map.Entry<String, String> par : MENSAGENS.entrySet()) {
            if (bruta.contains(par.getKey())) {
                return par.getValue();
            }
        }

        // Nenhuma restricao reconhecida pelo nome: cai nos codigos gerais
        // do MySQL, que ainda dizem bem mais que a excecao crua.
        switch (e.getErrorCode()) {
            case 1062:
                return "Ja existe um registro com esse valor unico.";
            case 1048:
                return "Um campo obrigatorio ficou em branco.";
            case 1451:
                return "Nao da para excluir: ha outros registros que dependem deste.";
            case 1452:
                return "O registro referenciado nao existe.";
            case 3819:
                return "O valor informado esta fora do dominio aceito pelo banco.";
            case 1406:
                return "Um dos textos informados e maior que o campo comporta.";
            default:
                return "Nao foi possivel " + acaoEmCurso + ".\n"
                        + "Detalhe tecnico: " + e.getMessage();
        }
    }

    /** Atalho: ja devolve o ErroNegocio pronto para ser lancado. */
    public static ErroNegocio comoErroNegocio(SQLException e, String acaoEmCurso) {
        return new ErroNegocio(traduzir(e, acaoEmCurso), e);
    }
}
