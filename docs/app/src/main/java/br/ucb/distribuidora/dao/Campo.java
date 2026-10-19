package br.ucb.distribuidora.dao;

import java.util.List;

/**
 * Descricao de um campo do formulario de cadastro.
 *
 * O painel de CRUD e um so para as quatro entidades: ele monta a tela a
 * partir desta lista, em vez de existir uma classe de tela para cada
 * cadastro. Quem decide quais campos aparecem e cada DAO.
 */
public class Campo {

    public enum Tipo {
        /** Texto livre. */
        TEXTO,
        /** Numero inteiro. */
        INTEIRO,
        /** Valor com casas decimais. */
        DECIMAL,
        /** Data no formato aaaa-mm-dd. */
        DATA,
        /** Escolha entre opcoes vindas do banco. */
        LISTA
    }

    private final String nome;        // nome da coluna no banco
    private final String rotulo;      // o que aparece na tela
    private final Tipo tipo;
    private final boolean obrigatorio;
    private final List<ConsultaDAO.Opcao> opcoes;  // so para Tipo.LISTA

    public Campo(String nome, String rotulo, Tipo tipo, boolean obrigatorio) {
        this(nome, rotulo, tipo, obrigatorio, null);
    }

    public Campo(String nome, String rotulo, Tipo tipo, boolean obrigatorio,
                 List<ConsultaDAO.Opcao> opcoes) {
        this.nome = nome;
        this.rotulo = rotulo;
        this.tipo = tipo;
        this.obrigatorio = obrigatorio;
        this.opcoes = opcoes;
    }

    public String getNome() {
        return nome;
    }

    public String getRotulo() {
        return rotulo;
    }

    public Tipo getTipo() {
        return tipo;
    }

    public boolean isObrigatorio() {
        return obrigatorio;
    }

    public List<ConsultaDAO.Opcao> getOpcoes() {
        return opcoes;
    }
}
