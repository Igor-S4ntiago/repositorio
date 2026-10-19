package br.ucb.distribuidora.dao;

import br.ucb.distribuidora.db.ErroNegocio;

import java.math.BigDecimal;
import java.sql.Date;

/**
 * Converte o texto digitado na tela para o tipo que o banco espera.
 *
 * Sem isto, digitar "abc" no campo de preco faria o Java lancar uma
 * NumberFormatException, que nao e capturada pela tela e terminaria em
 * rastro de pilha no console -- exatamente o oposto do que o B1 pede.
 * Aqui o erro vira uma frase que o usuario entende, igual as recusas que
 * vem do banco.
 */
public class Conversor {

    private Conversor() {
    }

    /** Aceita virgula ou ponto como separador decimal. */
    public static BigDecimal decimal(String valor, String rotulo) throws ErroNegocio {
        if (valor == null || valor.isBlank()) {
            throw new ErroNegocio("Preencha o campo " + rotulo + ".");
        }
        try {
            return new BigDecimal(valor.trim().replace(",", "."));
        } catch (NumberFormatException e) {
            throw new ErroNegocio(
                    "O campo " + rotulo + " precisa ser um numero.\n"
                    + "Valor informado: " + valor, e);
        }
    }

    public static int inteiro(String valor, String rotulo) throws ErroNegocio {
        if (valor == null || valor.isBlank()) {
            throw new ErroNegocio("Preencha o campo " + rotulo + ".");
        }
        try {
            return Integer.parseInt(valor.trim());
        } catch (NumberFormatException e) {
            throw new ErroNegocio(
                    "O campo " + rotulo + " precisa ser um numero inteiro.\n"
                    + "Valor informado: " + valor, e);
        }
    }

    /** Espera o formato aaaa-mm-dd. */
    public static Date data(String valor, String rotulo) throws ErroNegocio {
        if (valor == null || valor.isBlank()) {
            throw new ErroNegocio("Preencha o campo " + rotulo + ".");
        }
        try {
            return Date.valueOf(valor.trim());
        } catch (IllegalArgumentException e) {
            throw new ErroNegocio(
                    "O campo " + rotulo + " precisa estar no formato aaaa-mm-dd.\n"
                    + "Valor informado: " + valor, e);
        }
    }

    /** Aceita apenas 0 ou 1, como exige a restricao ck_funcionario_ativo. */
    public static int zeroOuUm(String valor, String rotulo) throws ErroNegocio {
        int n = inteiro(valor, rotulo);
        if (n != 0 && n != 1) {
            throw new ErroNegocio(
                    "O campo " + rotulo + " aceita apenas 1 para sim ou 0 para nao.");
        }
        return n;
    }
}
