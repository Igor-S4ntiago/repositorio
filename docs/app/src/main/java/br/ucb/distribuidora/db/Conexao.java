package br.ucb.distribuidora.db;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Abre conexoes com o banco da distribuidora.
 *
 * As credenciais NAO ficam no codigo-fonte. Elas sao lidas do arquivo
 * config.properties, que esta no .gitignore e portanto nunca vai para o
 * repositorio. O repositorio versiona apenas o config.properties.exemplo.
 *
 * Artefato B2 do enunciado.
 *
 * Quando o config.properties nao existe, quem pede os dados ao usuario e
 * a TelaConexao, e e ela que grava o arquivo. Esta classe nao conhece a
 * interface grafica: ela so sabe ler, testar e guardar. Por isso os
 * metodos publicos abaixo vem em pares -- um que consulta o estado e um
 * que o altera -- e a orquestracao fica no Main.
 */
public class Conexao {

    private static final String ARQUIVO = "config.properties";

    /** Carregado uma unica vez, na primeira conexao. */
    private static Properties config;

    /** Classe utilitaria: nao deve ser instanciada. */
    private Conexao() {
    }

    /**
     * Devolve uma conexao nova. Quem chama e responsavel por fechar,
     * de preferencia com try-with-resources.
     */
    public static Connection abrir() throws ErroNegocio {
        Properties p = carregarConfig();
        try {
            return conectar(p);
        } catch (SQLException e) {
            throw new ErroNegocio(
                    "Nao foi possivel conectar ao banco de dados.\n"
                    + "Confira se o MySQL esta no ar e se o usuario e a senha "
                    + "estao corretos.", e);
        }
    }

    /** Conexao crua, sem traduzir a excecao. Usada tambem pelo teste. */
    private static Connection conectar(Properties p) throws SQLException {
        return DriverManager.getConnection(
                p.getProperty("db.url"),
                p.getProperty("db.usuario"),
                p.getProperty("db.senha"));
    }

    // -----------------------------------------------------------------
    // Estado da configuracao
    // -----------------------------------------------------------------

    /** Ha um config.properties disponivel, no disco ou dentro do jar? */
    public static boolean estaConfigurada() {
        if (Files.exists(Path.of(ARQUIVO))) {
            return true;
        }
        try (InputStream in = Conexao.class.getClassLoader()
                .getResourceAsStream(ARQUIVO)) {
            return in != null;
        } catch (IOException e) {
            return false;
        }
    }

    /**
     * Tenta conectar com o que esta configurado.
     *
     * @return null quando a conexao funciona, ou a mensagem do erro
     */
    public static String testar() {
        try {
            Properties p = carregarConfig();
            try (Connection c = conectar(p)) {
                return c.isValid(5) ? null : "A conexao abriu mas nao respondeu.";
            }
        } catch (ErroNegocio e) {
            return e.getMessage();
        } catch (SQLException e) {
            return e.getMessage();
        }
    }

    /**
     * Testa um conjunto de credenciais sem adotar nenhuma delas. E o que
     * o botao "Testar" da TelaConexao usa antes de salvar.
     *
     * @return null quando funciona, ou a mensagem do erro
     */
    public static String testar(Properties candidata) {
        try (Connection c = conectar(candidata)) {
            return c.isValid(5) ? null : "A conexao abriu mas nao respondeu.";
        } catch (SQLException e) {
            return e.getMessage();
        }
    }

    /** Adota estas credenciais nesta execucao, sem gravar em disco. */
    public static synchronized void definir(Properties p) {
        config = p;
    }

    /**
     * Grava as credenciais no config.properties, na pasta de onde a
     * aplicacao foi iniciada. E o mesmo arquivo que o
     * config.properties.exemplo documenta, e continua fora do
     * repositorio pelo .gitignore.
     */
    public static void salvar(Properties p) throws ErroNegocio {
        // O arquivo e escrito a mao em vez de usar Properties.store, que
        // escaparia os dois-pontos e os iguais da URL e deixaria uma linha
        // ilegivel para quem abrisse o arquivo depois. No formato
        // properties so o primeiro separador conta, portanto a URL pode
        // ficar escrita do jeito natural. A unica escapagem necessaria e a
        // da propria barra invertida, que pode aparecer numa senha.
        String texto = ""
                + "# Gerado pela tela de conexao da aplicacao.\n"
                + "# Este arquivo esta no .gitignore e nao vai para o repositorio.\n"
                + "\n"
                + "db.url=" + escapar(p.getProperty("db.url")) + "\n"
                + "db.usuario=" + escapar(p.getProperty("db.usuario")) + "\n"
                + "db.senha=" + escapar(p.getProperty("db.senha")) + "\n";

        try (OutputStream out = Files.newOutputStream(Path.of(ARQUIVO))) {
            out.write(texto.getBytes(java.nio.charset.StandardCharsets.ISO_8859_1));
        } catch (IOException e) {
            throw new ErroNegocio(
                    "As credenciais funcionam, mas nao foi possivel gravar o "
                    + ARQUIVO + " nesta pasta.\n"
                    + "A aplicacao segue funcionando; na proxima execucao os "
                    + "dados terao de ser informados de novo.", e);
        }
    }

    private static String escapar(String valor) {
        return valor == null ? "" : valor.replace("\\", "\\\\");
    }

    /**
     * Monta a URL de conexao a partir das partes que o usuario informa.
     *
     * Os tres parametros do fim nao sao decoracao. O useSSL=false evita o
     * aviso de certificado em servidor local; o allowPublicKeyRetrieval e
     * exigido pelo MySQL 8, que autentica por caching_sha2_password e sem
     * ele recusa a primeira conexao sem SSL; e o serverTimezone impede
     * que as datas cheguem deslocadas quando o fuso da JVM e o do
     * servidor nao coincidem, o que importa aqui porque a RN10 guarda
     * data e hora das movimentacoes.
     */
    public static String montarUrl(String servidor, String porta, String banco) {
        return "jdbc:mysql://" + servidor + ":" + porta + "/" + banco
                + "?useSSL=false"
                + "&allowPublicKeyRetrieval=true"
                + "&serverTimezone=America/Sao_Paulo";
    }

    // -----------------------------------------------------------------
    // Leitura do arquivo
    // -----------------------------------------------------------------

    /**
     * Le o config.properties. Procura primeiro na pasta onde a aplicacao
     * foi iniciada; se nao achar, procura dentro do proprio jar. Assim as
     * credenciais podem ser trocadas sem recompilar nada.
     */
    private static synchronized Properties carregarConfig() throws ErroNegocio {
        if (config != null) {
            return config;
        }

        Properties p = new Properties();
        Path noDisco = Path.of(ARQUIVO);

        try {
            if (Files.exists(noDisco)) {
                try (InputStream in = new FileInputStream(noDisco.toFile())) {
                    p.load(in);
                }
            } else {
                try (InputStream in = Conexao.class.getClassLoader()
                        .getResourceAsStream(ARQUIVO)) {
                    if (in == null) {
                        throw new ErroNegocio(
                                "Arquivo " + ARQUIVO + " nao encontrado.\n"
                                + "Copie o config.properties.exemplo para "
                                + "config.properties e preencha os dados de "
                                + "acesso ao banco.");
                    }
                    p.load(in);
                }
            }
        } catch (IOException e) {
            throw new ErroNegocio("Falha ao ler o " + ARQUIVO + ".", e);
        }

        for (String chave : new String[] { "db.url", "db.usuario", "db.senha" }) {
            if (p.getProperty(chave) == null) {
                throw new ErroNegocio(
                        "A chave " + chave + " esta faltando no " + ARQUIVO + ".");
            }
        }

        config = p;
        return config;
    }
}
