package br.ucb.distribuidora.dao;

import br.ucb.distribuidora.db.Conexao;
import br.ucb.distribuidora.db.ErroNegocio;
import br.ucb.distribuidora.db.TradutorErro;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;

/**
 * Registro de uma venda. E a operacao transacional multitabela exigida
 * no B1 e documentada no B3 -- o item central da Etapa 2.
 *
 * Uma unica transacao toca cinco tabelas:
 *
 *   1. pedido                 cabecalho da venda
 *   2. item_pedido            uma linha por produto, com o preco do dia
 *   3. estoque                abate o saldo do produto
 *   4. movimentacao_estoque   registra a saida, com data e hora (RN10)
 *   5. pagamento              cria a cobranca pendente (RN13)
 *
 * Ou os cinco passos acontecem, ou nenhum acontece. Se qualquer um
 * falhar, o rollback desfaz os anteriores e o banco volta exatamente ao
 * estado em que estava.
 *
 * Nivel de isolamento: READ COMMITTED, declarado explicitamente. O padrao
 * do InnoDB e REPEATABLE READ, que seguraria a leitura do saldo no valor
 * do inicio da transacao -- indesejavel aqui, porque duas vendas
 * simultaneas do mesmo produto precisam enxergar o abatimento uma da
 * outra. O bloqueio de linha do SELECT ... FOR UPDATE e o que serializa
 * as duas, e nao o nivel de isolamento.
 */
public class VendaDAO {

    /** Le o saldo e TRAVA a linha do estoque ate o fim da transacao. */
    private static final String SQL_TRAVA_ESTOQUE =
            "SELECT e.idestoque, e.quantidade_atual, p.nome, p.preco_venda "
            + "  FROM estoque e "
            + "  JOIN produto p ON p.idproduto = e.produto_idproduto "
            + " WHERE e.produto_idproduto = ? "
            + "   FOR UPDATE";

    private static final String SQL_INSERE_PEDIDO =
            "INSERT INTO pedido (data_pedido, status, cliente_pessoa_idpessoa) "
            + "VALUES (NOW(), 'ABERTO', ?)";

    private static final String SQL_INSERE_ITEM =
            "INSERT INTO item_pedido "
            + "       (pedido_idpedido, produto_idproduto, quantidade, preco_unitario) "
            + "VALUES (?, ?, ?, ?)";

    private static final String SQL_ABATE_ESTOQUE =
            "UPDATE estoque "
            + "   SET quantidade_atual = quantidade_atual - ?, "
            + "       data_atualizacao = NOW() "
            + " WHERE idestoque = ?";

    private static final String SQL_INSERE_MOVIMENTACAO =
            "INSERT INTO movimentacao_estoque "
            + "       (tipo, quantidade, data_hora, estoque_idestoque) "
            + "VALUES ('SAIDA', ?, NOW(), ?)";

    private static final String SQL_INSERE_PAGAMENTO =
            "INSERT INTO pagamento "
            + "       (forma_pagamento, status_pagamento, data_pagamento, pedido_idpedido) "
            + "VALUES (?, 'PENDENTE', NULL, ?)";

    /**
     * Grava a venda inteira em uma transacao.
     *
     * @param idCliente      cliente que esta comprando
     * @param formaPagamento PIX, Boleto, Cartao de Credito...
     * @param itens          produtos e quantidades
     * @param forcarFalha    quando true, provoca um erro de proposito
     *                       depois de gravar tudo, para demonstrar o
     *                       rollback na apresentacao (B3)
     * @return o numero do pedido gerado
     */
    public int registrarVenda(int idCliente,
                              String formaPagamento,
                              List<ItemVenda> itens,
                              boolean forcarFalha) throws ErroNegocio {

        if (itens == null || itens.isEmpty()) {
            // RN08: todo pedido tem pelo menos um item.
            throw new ErroNegocio("Inclua ao menos um produto na venda (RN08).");
        }

        Connection con = null;
        try {
            con = Conexao.abrir();

            // --- inicio da transacao -------------------------------------
            con.setTransactionIsolation(Connection.TRANSACTION_READ_COMMITTED);
            con.setAutoCommit(false);

            int idPedido = inserirPedido(con, idCliente);

            for (ItemVenda item : itens) {
                // 1. trava a linha do estoque e descobre saldo e preco
                int idEstoque;
                int saldo;
                String nome;
                BigDecimal precoDoDia;

                try (PreparedStatement ps = con.prepareStatement(SQL_TRAVA_ESTOQUE)) {
                    ps.setInt(1, item.getIdProduto());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new ErroNegocio(
                                    "O produto " + item.getNomeProduto()
                                    + " nao tem posicao de estoque cadastrada.");
                        }
                        idEstoque = rs.getInt("idestoque");
                        saldo = rs.getInt("quantidade_atual");
                        nome = rs.getString("nome");
                        precoDoDia = rs.getBigDecimal("preco_venda");
                    }
                }

                // 2. confere o saldo antes de tentar gravar, para poder dar
                //    uma mensagem com numero em vez de so recusar (RN11).
                //    A restricao ck_estoque_quantidade continua no banco
                //    como ultima linha de defesa.
                if (saldo < item.getQuantidade()) {
                    throw new ErroNegocio(
                            "Estoque insuficiente de " + nome + ".\n"
                            + "Pedido: " + item.getQuantidade()
                            + "    Disponivel: " + saldo + "\n"
                            + "A venda inteira foi cancelada (RN11).");
                }

                // 3. o item guarda o preco praticado hoje (RN08)
                try (PreparedStatement ps = con.prepareStatement(SQL_INSERE_ITEM)) {
                    ps.setInt(1, idPedido);
                    ps.setInt(2, item.getIdProduto());
                    ps.setInt(3, item.getQuantidade());
                    ps.setBigDecimal(4, precoDoDia);
                    ps.executeUpdate();
                }

                // 4. abate o estoque
                try (PreparedStatement ps = con.prepareStatement(SQL_ABATE_ESTOQUE)) {
                    ps.setInt(1, item.getQuantidade());
                    ps.setInt(2, idEstoque);
                    ps.executeUpdate();
                }

                // 5. deixa o rastro da saida, com data e hora (RN09 e RN10)
                try (PreparedStatement ps = con.prepareStatement(SQL_INSERE_MOVIMENTACAO)) {
                    ps.setInt(1, item.getQuantidade());
                    ps.setInt(2, idEstoque);
                    ps.executeUpdate();
                }
            }

            // 6. cobranca pendente para o pedido (RN13)
            try (PreparedStatement ps = con.prepareStatement(SQL_INSERE_PAGAMENTO)) {
                ps.setString(1, formaPagamento);
                ps.setInt(2, idPedido);
                ps.executeUpdate();
            }

            // Falha provocada de proposito para a demonstracao do B3.
            // Tudo acima ja foi executado; o rollback a seguir desfaz.
            if (forcarFalha) {
                throw new ErroNegocio(
                        "Falha provocada de proposito no fim da transacao.\n"
                        + "Os cinco passos ja tinham sido executados. O ROLLBACK "
                        + "desfez todos: nenhum pedido foi criado e o estoque "
                        + "continua como estava.");
            }

            con.commit();
            return idPedido;

        } catch (SQLException e) {
            desfazer(con);
            throw TradutorErro.comoErroNegocio(e, "registrar a venda");
        } catch (ErroNegocio e) {
            desfazer(con);
            throw e;
        } finally {
            fechar(con);
        }
    }

    /** Insere o cabecalho e devolve a chave gerada pelo AUTO_INCREMENT. */
    private int inserirPedido(Connection con, int idCliente) throws SQLException, ErroNegocio {
        try (PreparedStatement ps = con.prepareStatement(
                SQL_INSERE_PEDIDO, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, idCliente);
            ps.executeUpdate();
            try (ResultSet chaves = ps.getGeneratedKeys()) {
                if (!chaves.next()) {
                    throw new ErroNegocio("O banco nao devolveu o numero do pedido.");
                }
                return chaves.getInt(1);
            }
        }
    }

    private void desfazer(Connection con) {
        if (con == null) {
            return;
        }
        try {
            con.rollback();
        } catch (SQLException ignorado) {
            // Se nem o rollback funciona, a conexao caiu: ao fechar sem
            // commit, o proprio InnoDB desfaz a transacao.
        }
    }

    private void fechar(Connection con) {
        if (con == null) {
            return;
        }
        try {
            con.setAutoCommit(true);
            con.close();
        } catch (SQLException ignorado) {
            // Nada util a fazer ao fechar.
        }
    }
}
