package br.ucb.distribuidora.dao;

/**
 * Uma linha da venda que esta sendo montada na tela, antes de virar
 * registro no banco.
 *
 * O preco nao vem daqui: quem decide o preco e o banco, no momento em que
 * a venda e gravada, lendo produto.preco_venda. Assim a tela nao consegue
 * vender por um valor que nao seja o de tabela, e o valor gravado em
 * item_pedido.preco_unitario fica sendo o praticado naquele dia (RN08).
 */
public class ItemVenda {

    private final int idProduto;
    private final String nomeProduto;
    private final int quantidade;

    public ItemVenda(int idProduto, String nomeProduto, int quantidade) {
        this.idProduto = idProduto;
        this.nomeProduto = nomeProduto;
        this.quantidade = quantidade;
    }

    public int getIdProduto() {
        return idProduto;
    }

    public String getNomeProduto() {
        return nomeProduto;
    }

    public int getQuantidade() {
        return quantidade;
    }
}
