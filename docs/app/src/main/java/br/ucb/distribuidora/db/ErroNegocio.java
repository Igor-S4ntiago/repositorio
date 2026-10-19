package br.ucb.distribuidora.db;

/**
 * Erro com mensagem pronta para ser mostrada ao usuario.
 *
 * O enunciado pede, no B1, que uma violacao de restricao do banco chegue
 * a tela como texto compreensivel, e nao como a excecao bruta do driver.
 * Toda a aplicacao trabalha com esta excecao: as classes DAO capturam a
 * SQLException, passam pelo TradutorErro e lancam um ErroNegocio.
 */
public class ErroNegocio extends Exception {

    private static final long serialVersionUID = 1L;

    public ErroNegocio(String mensagem) {
        super(mensagem);
    }

    public ErroNegocio(String mensagem, Throwable causa) {
        super(mensagem, causa);
    }
}
