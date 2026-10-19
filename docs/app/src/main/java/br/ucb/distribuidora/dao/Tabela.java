package br.ucb.distribuidora.dao;

import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * Resultado de uma consulta, pronto para virar JTable.
 *
 * Em vez de criar uma classe de modelo para cada consulta, as telas de
 * consulta e de relatorio recebem este objeto, que carrega os nomes das
 * colunas e as linhas. Os nomes vem do proprio ResultSet, ou seja, sao os
 * apelidos escritos no SQL -- o que mantem a consulta como unica fonte da
 * verdade sobre o que aparece na tela.
 */
public class Tabela {

    private final String[] colunas;
    private final List<Object[]> linhas;

    private Tabela(String[] colunas, List<Object[]> linhas) {
        this.colunas = colunas;
        this.linhas = linhas;
    }

    /** Le o ResultSet inteiro e monta a tabela. */
    public static Tabela de(ResultSet rs) throws SQLException {
        ResultSetMetaData meta = rs.getMetaData();
        int n = meta.getColumnCount();

        String[] cabecalho = new String[n];
        for (int i = 0; i < n; i++) {
            cabecalho[i] = meta.getColumnLabel(i + 1);
        }

        List<Object[]> dados = new ArrayList<>();
        while (rs.next()) {
            Object[] linha = new Object[n];
            for (int i = 0; i < n; i++) {
                linha[i] = rs.getObject(i + 1);
            }
            dados.add(linha);
        }
        return new Tabela(cabecalho, dados);
    }

    public String[] getColunas() {
        return colunas;
    }

    public Object[][] getLinhas() {
        return linhas.toArray(new Object[0][]);
    }

    public int getQuantidadeLinhas() {
        return linhas.size();
    }
}
