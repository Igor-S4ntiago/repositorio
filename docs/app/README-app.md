# Aplicação — Etapa 2

Aplicação desktop em Java que opera o banco construído na Etapa 1.
Swing para a interface, JDBC puro para o acesso aos dados. Sem ORM: o
esquema continua sendo o `01_ddl.sql` escrito pela equipe, e todo o SQL
da aplicação está visível nas classes `dao`, de modo que o plano de
execução possa ser analisado no artefato B4.

## Pré-requisitos

- **JDK 21 ou superior**
- **Maven 3.8 ou superior** (baixa o driver MySQL automaticamente)
- O banco da Etapa 1 criado e carregado

## Preparar o banco

```bash
mysql -u SEU_USUARIO -p < sql/01_ddl.sql
mysql -u SEU_USUARIO -p < sql/02_carga.sql
mysql -u SEU_USUARIO -p < sql/04_etapa2.sql
```

O `04_etapa2.sql` acrescenta a tabela `usuario`, com senha em hash e sal,
e as duas visões que alimentam as telas.

Há também o `sql/banco-completo.sql`, que é a junção desses três mais o
`INSERT` do usuário `admin`. Ele existe para subir o banco inteiro com
uma importação só, em máquina onde nada disso foi rodado ainda. Os três
scripts separados continuam sendo a entrega, porque é assim que estão
documentados no relatório.

## Configurar o acesso

As credenciais não estão no código. Na primeira execução, a aplicação
abre uma janela pedindo servidor, porta, banco, usuário e senha, testa a
conexão e grava o `config.properties`. Não é preciso editar arquivo
nenhum à mão.

Quem preferir preencher antes pode copiar o modelo:

```bash
cp config.properties.exemplo config.properties
```

De um jeito ou de outro, o `config.properties` está no `.gitignore` e
nunca vai para o repositório. O que é versionado é apenas o arquivo de
exemplo.

A janela aparece também quando o `config.properties` existe mas não
conecta — senha trocada, serviço fora do ar, banco não importado. Isso
evita a situação de um arquivo com senha errada obrigar a sair da
aplicação, editar e entrar de novo.

## Compilar

```bash
mvn clean package
```

Gera `target/distribuidora-app.jar`, com o driver dentro.

## Criar o primeiro usuário

O `banco-completo.sql` já cria o `admin` com a senha `senha123`, então
no caminho normal não há nada a fazer aqui.

Quem subiu o banco pelos três scripts separados fica sem usuário, e sem
usuário não há como passar da tela de login. O primeiro é criado pelo
terminal:

```bash
java -jar target/distribuidora-app.jar --criar-usuario admin senha123 ADMIN
```

A senha é gravada em hash com sal; em nenhum momento ela aparece em texto
claro no banco. Para ver o par sal/hash de uma senha, por exemplo para
montar um `INSERT` à mão:

```bash
java -jar target/distribuidora-app.jar --hash senha123
```

## Executar

```bash
java -jar target/distribuidora-app.jar
```

## O que cada tela atende

| Tela | Artefato | O que faz |
|---|---|---|
| Conexão | B2 | Pede e testa o acesso ao banco; grava o `config.properties` |
| Login | B5 | Senha conferida contra hash e sal (PBKDF2, 120 mil iterações) |
| Nova venda | B1, B3 | A operação transacional: cinco tabelas em uma transação |
| Consultas | B1, B2 | Duas consultas parametrizadas com junção e agregação |
| Relatório | B1 | Alimentado pela visão `vw_faturamento_categoria` |
| Produtos, Fornecedores, Clientes, Funcionários | B1 | CRUD completo das quatro entidades |

As abas visíveis dependem do perfil do usuário: estoquista não vê
clientes, e só o administrador vê funcionários.

## A operação transacional

Registrar uma venda toca cinco tabelas numa única transação:

1. `pedido` — cabeçalho da venda
2. `item_pedido` — uma linha por produto, com o preço do dia (RN08)
3. `estoque` — abate o saldo
4. `movimentacao_estoque` — registra a saída com data e hora (RN10)
5. `pagamento` — cria a cobrança pendente (RN13)

Ou os cinco acontecem, ou nenhum acontece.

**Nível de isolamento:** `READ COMMITTED`, declarado no código. O padrão
do InnoDB é `REPEATABLE READ`, que seguraria a leitura do saldo no valor
do início da transação — indesejável aqui, porque duas vendas simultâneas
do mesmo produto precisam enxergar o abatimento uma da outra. Quem
serializa as duas é o `SELECT ... FOR UPDATE` sobre a linha do estoque,
não o nível de isolamento.

**Demonstração do rollback (B3).** Há duas formas de provocar a falha:

- Vender mais do que existe em estoque. A aplicação lê o saldo com a
  linha travada, recusa e desfaz tudo. A restrição
  `ck_estoque_quantidade` continua no banco como última linha de defesa.
- Marcar a caixa *Provocar falha no fim da transação*. Os cinco passos
  são executados e só então o erro acontece, o que mostra que o
  `ROLLBACK` desfaz até o que já tinha sido gravado.

Depois de qualquer uma das duas, a consulta `V01` do `03_consultas.sql`
continua voltando vazia: o banco permaneceu íntegro.

## Tratamento de erro visível ao usuário

Toda restrição do `01_ddl.sql` tem nome, e o MySQL devolve esse nome na
mensagem de erro. A classe `TradutorErro` usa isso para dar uma resposta
específica em vez de mostrar a exceção do driver.

| Tentativa | O que o usuário vê |
|---|---|
| Cadastrar CPF repetido | "Já existe uma pessoa cadastrada com esse CPF." |
| Vender além do estoque | "Estoque insuficiente de X. Pedido: 50  Disponível: 12" |
| Excluir produto já vendido | "Produto já foi vendido e não pode ser excluído." |
| Excluir cliente com pedidos | "O cliente já tem pedidos e não pode ser excluído." |

## Resistência a injeção de SQL (B2)

Nenhuma consulta é montada por concatenação de string. Todo valor
informado pelo usuário entra como parâmetro de `PreparedStatement`.

**Demonstração para o relatório.** Na aba *Nova venda*, no campo
*Filtrar produto*, digite:

```
' OR '1'='1
```

O combo fica vazio e a aplicação avisa que nenhum produto corresponde ao
filtro. O texto foi procurado como **nome de produto**, não executado
como comando: o driver envia o SQL e os valores separados, de modo que o
conteúdo digitado nunca é interpretado como parte da consulta.

Se o filtro fosse concatenado, o `WHERE produto LIKE '%' OR '1'='1%'`
devolveria o catálogo inteiro.

## Organização do código

```
src/main/java/br/ucb/distribuidora/
├── Main.java              entrada; também cria usuário pelo terminal
├── db/
│   ├── Conexao.java       lê o config.properties, testa e abre conexões
│   ├── ErroNegocio.java   exceção com mensagem pronta para a tela
│   └── TradutorErro.java  nome da restrição → frase para o usuário
├── seguranca/
│   └── Senha.java         PBKDF2 com sal por usuário
├── dao/                   todo o SQL da aplicação
│   ├── VendaDAO.java      a operação transacional
│   ├── ConsultaDAO.java   consultas parametrizadas e relatório
│   ├── UsuarioDAO.java    login
│   └── ProdutoDAO, ClienteDAO, FornecedorDAO, FuncionarioDAO
└── ui/                    telas Swing
    ├── TelaConexao.java   pede e testa o acesso ao banco
    ├── TelaLogin.java     login da aplicação
    └── Janela e Painel*   janela principal e as abas
```

`Conexao` não conhece a interface gráfica: ela sabe ler, testar e guardar
credenciais, e quem decide abrir a `TelaConexao` é o `Main`. É o que
mantém o pacote `db` utilizável sem Swing — por exemplo nos modos de
terminal, que rodam sem janela nenhuma.

`PainelCadastro` é um painel genérico: ele monta tabela e formulário a
partir do que cada `CadastroDao` descreve. Por isso os quatro cadastros
usam a mesma tela, e cada DAO cuida apenas do seu SQL.
