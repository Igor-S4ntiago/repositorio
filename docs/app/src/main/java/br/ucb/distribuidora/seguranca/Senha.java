package br.ucb.distribuidora.seguranca;

import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.KeySpec;
import java.util.HexFormat;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/**
 * Guarda de senha com hash e sal, como pede o artefato B5.
 *
 * A senha em texto claro nunca e gravada e nunca sai desta classe. O que
 * vai para a tabela usuario sao duas colunas:
 *
 *   senha_sal  - 16 bytes sorteados por senha, em hexadecimal (32 chars)
 *   senha_hash - o resultado do PBKDF2 sobre a senha mais o sal (64 chars)
 *
 * O sal e por usuario, e nao fixo no sistema. Isso faz com que duas
 * pessoas com a mesma senha tenham hashes diferentes, o que inutiliza
 * tabela arco-iris e impede descobrir, so de olhar o banco, que dois
 * usuarios escolheram a mesma senha.
 *
 * PBKDF2 e proposital: ele e lento de reptir muitas vezes, o que encarece
 * a tentativa de quebra por forca bruta. Usamos 120 mil iteracoes.
 */
public class Senha {

    private static final String ALGORITMO = "PBKDF2WithHmacSHA256";
    private static final int ITERACOES = 120_000;
    private static final int BYTES_SAL = 16;   // 32 caracteres em hexadecimal
    private static final int BITS_HASH = 256;  // 64 caracteres em hexadecimal

    private static final SecureRandom SORTEIO = new SecureRandom();
    private static final HexFormat HEX = HexFormat.of();

    private Senha() {
    }

    /** Sorteia um sal novo, em hexadecimal, para um usuario novo. */
    public static String novoSal() {
        byte[] sal = new byte[BYTES_SAL];
        SORTEIO.nextBytes(sal);
        return HEX.formatHex(sal);
    }

    /**
     * Calcula o hash da senha com o sal informado.
     *
     * @param senha  texto digitado pelo usuario
     * @param salHex sal em hexadecimal, vindo de novoSal() ou do banco
     * @return hash em hexadecimal, com 64 caracteres
     */
    public static String calcularHash(char[] senha, String salHex) {
        try {
            KeySpec spec = new PBEKeySpec(
                    senha, HEX.parseHex(salHex), ITERACOES, BITS_HASH);
            SecretKeyFactory fabrica = SecretKeyFactory.getInstance(ALGORITMO);
            return HEX.formatHex(fabrica.generateSecret(spec).getEncoded());
        } catch (NoSuchAlgorithmException | InvalidKeySpecException e) {
            // Nenhum dos dois acontece em uma JVM padrao: o algoritmo faz
            // parte do Java desde a versao 8.
            throw new IllegalStateException("Falha ao calcular o hash da senha", e);
        }
    }

    /**
     * Confere a senha digitada contra o que esta gravado.
     *
     * A comparacao percorre os dois textos inteiros mesmo quando ja
     * encontrou diferenca, para que o tempo de resposta nao denuncie
     * quantos caracteres estavam certos.
     */
    public static boolean conferir(char[] digitada, String salHex, String hashGravado) {
        String calculado = calcularHash(digitada, salHex);
        if (calculado.length() != hashGravado.length()) {
            return false;
        }
        int diferenca = 0;
        for (int i = 0; i < calculado.length(); i++) {
            diferenca |= calculado.charAt(i) ^ hashGravado.charAt(i);
        }
        return diferenca == 0;
    }
}
