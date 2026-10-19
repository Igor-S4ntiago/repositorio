# Sistema de Gestão para Distribuidora de Bebidas

Projeto Final da disciplina **Laboratório de Banco de Dados** (GPE17M40083) —
Bacharelado em Engenharia de Software, Universidade Católica de Brasília,
2026/2. Docente: Samuel Novais Moura Júnior.

**Etapa 1** — modelagem conceitual, lógica e implementação física.
**Etapa 2** — aplicação, transações, concorrência e controle de acesso.

## Equipe

- Igor Santiago Pereira da Silva
- João Arantes Rodrigues
- Jander Matheus Correia de Lima Pinto

---

## Domínio

Uma distribuidora de bebidas. O banco cobre o cadastro de clientes,
funcionários, produtos, categorias e fornecedores, a venda por pedidos, o
controle de estoque com histórico datado de movimentações, o pagamento e a
entrega.

O modelo tem **13 relações e 58 atributos**. Inclui uma especialização total
e disjunta (`pessoa` em `cliente` e `funcionario`), um autorrelacionamento
(a hierarquia de supervisão em `funcionario`), dois relacionamentos N:N com
atributo próprio, mapeados como entidades associativas
(`produto_fornecedor` e `item_pedido`), e uma entidade fraca, identificada
por dependência (`movimentacao_estoque`, que só se distingue pelo estoque a
que pertence mais a data e hora em que ocorreu).

---

## Estrutura do repositório

```
.
├── docs/
│
├── app/
│   ├── pom.xml                  projeto Maven
│   ├── src/                     26 classes Java
│   ├── config.properties.exemplo
│   ├── .gitignore
│   └── README-app.md            documentação técnica da aplicação
├── sql/
│   ├── 01_ddl.sql               estrutura: o banco e as treze tabelas
│   ├── 02_carga.sql             dados: 1.271 registros
│   ├── 03_consultas.sql         quinze consultas e três conferências
│   ├── 04_etapa2.sql            tabela de usuários e visões da aplicação
│   └── banco-completo.sql       os quatro acima num arquivo só
|
│   ├── relatorio-etapa1.pdf     artefatos A1 a A5
│   ├── relatorio-etapa2.pdf     artefatos B1 a B8
│   ├── mer-conceitual.pdf       modelo entidade-relacionamento (Chen)
│   ├── mer-conceitual.dot       arquivo-fonte do diagrama
│   ├── modelo-logico.pdf        esquema relacional
│   └── dicionario-dados.pdf     dicionário no formato do Anexo A
└── COMO-RODAR.md                passo a passo em máquina limpa
├── LEIA-PRIMEIRO.md             instruções para a execução
└── README.md
```

---

## Pré-requisitos

- **MySQL 8.0.16 ou superior.** A versão importa: abaixo de 8.0.16 o MySQL
  aceita a sintaxe das restrições `CHECK` e as ignora silenciosamente, o que
  desativaria as doze restrições de domínio do modelo.
- **Java 21 ou superior**, apenas para a aplicação da Etapa 2.
- Um cliente SQL: MySQL Workbench, a linha de comando `mysql`, ou a aba
  *Services* do NetBeans.

---

## Como subir o banco

### Caminho curto: um arquivo só

```
sql/banco-completo.sql
```

Ele apaga o banco, recria a estrutura, carrega os dados, cria a tabela de
usuários, as visões e o usuário administrador da aplicação. No fim imprime
uma tabela de conferência que deve mostrar:

| conferência | esperado |
|---|---|
| versão do MySQL | 8.0.16 ou maior |
| produtos | 60 |
| pedidos | 70 |
| movimentações de estoque | 374 |
| usuário da aplicação | 1 (admin) |

> O arquivo **começa apagando** o banco `distribuidora_bebidas`, se existir.
> É o que permite reimportar sem erro. Se houver um banco com esse nome que
> importe conservar, renomeie antes.

### Caminho longo: os scripts separados

Nesta ordem, em base limpa:

```bash
mysql -u SEU_USUARIO -p < sql/01_ddl.sql
mysql -u SEU_USUARIO -p < sql/02_carga.sql
mysql -u SEU_USUARIO -p < sql/04_etapa2.sql
mysql -u SEU_USUARIO -p < sql/03_consultas.sql   # opcional: só consulta
```

Por este caminho a tabela `usuario` fica vazia, e sem usuário não há como
entrar na aplicação. Crie o primeiro pelo terminal:

```bash
java -jar distribuidora-app.jar --criar-usuario admin senha123 ADMIN
```

### Sobre o modo de atualização segura

O MySQL Workbench liga por padrão o modo de atualização segura, que recusa
`DELETE` sem `WHERE` sobre coluna de chave e devolve o erro 1175. A limpeza
inicial do `02_carga.sql` apaga as tabelas inteiras de propósito — são treze
comandos assim.

O script resolve isso sozinho: guarda o valor do ajuste, desliga antes da
limpeza e devolve ao valor anterior no fim. Não é preciso configurar nada no
cliente.

---

## Como rodar a aplicação

### Pelo NetBeans 

**File → Open Project**, escolha a pasta `app` — a que tem o `pom.xml`.
Antes de rodar, faça **Clean and Build** uma vez: é nessa hora que o Maven
baixa o driver do MySQL e gera as classes. Depois, **Run**.

A classe principal, `br.ucb.distribuidora.Main`, já está declarada no
`pom.xml` pela propriedade `exec.mainClass`.


### O primeiro acesso

Na primeira execução em uma máquina nova, a aplicação abre uma janela
pedindo servidor, porta, banco, usuário e senha do MySQL. Ela **testa a
conexão antes de gravar**: se a senha estiver errada, o erro aparece ali,
com a causa, e não no meio de uma operação. Depois de funcionar, ela grava
o `config.properties` e não pergunta mais.

O login da aplicação é `admin` com a senha `senha123`.

> `config.properties` está no `.gitignore` e nunca vai para o repositório.
> O que é versionado é apenas o `config.properties.exemplo`.

---

## O que cada script faz

### `01_ddl.sql`

Cria o banco e as treze tabelas, na ordem das dependências. Declara 13
chaves primárias (`pk_`), 8 restrições de unicidade (`uq_`), 14 chaves
estrangeiras (`fk_`), 12 restrições de verificação (`ck_`) e 8 índices
(`idx_`). Toda chave estrangeira traz `ON DELETE` e `ON UPDATE` explícitos.

**Cada restrição vem comentada com a regra de negócio que atende.** Isso não
é só documentação: quando uma restrição é violada, o MySQL devolve o nome
dela na mensagem de erro, e é por esse nome que a aplicação descobre qual
regra foi quebrada e responde ao usuário. O comentário fecha o caminho de
volta, do erro para a restrição e da restrição para a regra.

### `02_carga.sql`

Insere 1.271 registros fictícios. Nomes, CPF, CNPJ, telefones e endereços
foram inventados e não correspondem a pessoas ou empresas reais.

A carga simula a operação em ordem cronológica: as entradas de compra são
lançadas antes das saídas de venda e, quando o saldo não cobriria uma venda,
uma reposição entra no dia anterior. Por isso nenhum saldo fica negativo e
`estoque.quantidade_atual` é exatamente a soma das entradas menos as saídas
registradas em `movimentacao_estoque`.

Casos de contorno colocados de propósito: cadastros sem telefone ou e-mail,
cliente sem endereço, clientes sem pedido, funcionário sem supervisor,
funcionários desligados, categorias sem produto, produtos sem fornecedor,
produtos nunca vendidos, produtos com estoque zerado, pedidos cancelados com
itens mas sem baixa de estoque, pagamentos pendentes e recusados sem data,
entregas sem responsável e itens cujo preço difere do preço de tabela.

Volume por tabela:

| Tabela | Linhas | Tabela | Linhas |
|---|---|---|---|
| `pessoa` | 105 | `pedido` | 70 |
| `cliente` | 63 | `item_pedido` | 199 |
| `funcionario` | 42 | `pagamento` | 70 |
| `categoria` | 40 | `entrega` | 42 |
| `fornecedor` | 40 | `estoque` | 60 |
| `produto` | 60 | `movimentacao_estoque` | 374 |
| `produto_fornecedor` | 106 | **Total** | **1.271** |

### `03_consultas.sql`

Quinze consultas comentadas, cada uma precedida da pergunta de negócio que
responde:

- **C01 a C05, básicas** — projeção, ordenação, `LIKE`, `BETWEEN`, `IN` e
  tratamento de nulos com `COALESCE` e `CASE`.
- **C06 a C10, junções e agregação** — faturamento por categoria, produtos
  nunca vendidos com `LEFT JOIN`, clientes recorrentes com `HAVING`,
  desempenho das entregas e valor imobilizado em estoque.
- **C11 a C15, avançadas** — subconsulta correlacionada, `EXISTS` com
  `NOT EXISTS`, expressões de tabela comuns para o ponto de recompra,
  consulta recursiva sobre a hierarquia de supervisão e funções de janela
  para a curva ABC.

### `04_etapa2.sql`

Acrescenta o que a aplicação precisa:

- a tabela `usuario`, com senha em hash e sal — não se confunde com os
  perfis de acesso do próprio MySQL: aqui é quem opera o sistema, lá é quem
  se conecta ao banco;
- a visão `vw_faturamento_categoria`, que alimenta a tela de relatório e
  concentra a regra de apuração, inclusive a exclusão dos pedidos
  cancelados exigida pela RN19;
- a visão `vw_posicao_estoque`, que reúne o saldo de cada produto com o seu
  nome e a sua categoria, e é de onde a tela de venda lê.

---

## Conferência da carga

A consulta `V01`, no fim de `03_consultas.sql`, é a verificação mais
importante do conjunto: ela compara, para cada produto, o saldo gravado em
`estoque.quantidade_atual` com a soma das entradas menos as saídas
registradas em `movimentacao_estoque`.

O saldo é um valor derivado, mantido por decisão de desempenho — calcular a
posição por agregação a cada leitura custaria percorrer todo o histórico do
produto. A `V01` é o controle dessa redundância, e o resultado esperado é
**nenhuma linha**.

Na Etapa 2 ela ganhou um segundo uso: é a prova de que o banco permaneceu
íntegro depois das demonstrações de falha de transação.

As outras duas: `V02` procura pedidos sem pagamento associado e `V03`
procura entregas com situação e data incoerentes. Ambas também devem voltar
vazias.

---

## A aplicação

Desktop em Java 21 com Swing, conectada ao MySQL por **JDBC puro, sem ORM**.
A escolha foi deliberada: o esquema continua sendo o `01_ddl.sql` escrito
pela equipe, e todo o SQL está visível nas classes `dao`, podendo ser lido,
explicado e ter o plano de execução analisado. Um mapeador
objeto-relacional esconderia exatamente o que a disciplina avalia.

São 26 classes em quatro pacotes:

```
br/ucb/distribuidora/
├── Main.java        entrada; também cria usuário pelo terminal
├── db/              conexão, tradução de erro do banco
├── seguranca/       hash de senha com sal
├── dao/             todo o SQL da aplicação
└── ui/              telas Swing
```

| Tela | O que faz |
|---|---|
| Conexão | Pede e testa o acesso ao banco na primeira execução |
| Login | Senha conferida contra hash e sal |
| Nova venda | A operação transacional: cinco tabelas em uma transação |
| Consultas | Duas consultas parametrizadas, com junção e agregação |
| Relatório | Consolidado, alimentado pela visão de faturamento |
| Produtos, Categorias, Fornecedores, Clientes, Funcionários | CRUD completo |

As abas visíveis dependem do perfil: estoquista não vê clientes, e só o
administrador vê funcionários.

### A operação transacional

Registrar uma venda toca cinco tabelas numa única transação: `pedido`,
`item_pedido` (com o preço do dia, pela RN08), `estoque` (abatendo o saldo),
`movimentacao_estoque` (com data e hora, pela RN10) e `pagamento` (pendente,
pela RN13). Ou as cinco mudam, ou nenhuma muda.

O nível de isolamento é **`READ COMMITTED`**, declarado no código em vez de
aceitar o padrão `REPEATABLE READ` do InnoDB. O padrão seguraria a leitura do
saldo no valor do início da transação, e duas vendas simultâneas do mesmo
produto precisam enxergar o abatimento uma da outra. Quem serializa as duas
é o `SELECT ... FOR UPDATE` sobre a linha do estoque, não o nível de
isolamento.

A restrição `ck_estoque_quantidade` continua no banco como última linha de
defesa: o saldo não fica negativo nem que a aplicação erre a conta.

### Demonstrações

- **Estoque insuficiente** — peça 9999 unidades na aba *Nova venda*. A
  aplicação recusa dizendo quanto há disponível, e nada é gravado.
- **Rollback** — marque *Provocar falha no fim da transação*. Os cinco
  passos são executados e só então o erro acontece, mostrando o `ROLLBACK`
  desfazer o que já havia sido gravado.
- **Injeção de SQL** — digite `' OR '1'='1` no campo *Filtrar produto*. A
  lista fica vazia: o texto foi procurado como nome de produto, não
  executado como comando.

Depois das duas primeiras, a `V01` continua voltando vazia.

Mais detalhes em `app/README-app.md`.

---

## Regras de negócio

As vinte regras estão numeradas de RN01 a RN20 e rastreadas até a
implementação no relatório da Etapa 1 e nos comentários do `01_ddl.sql`.
As que mais aparecem no código:

| | |
|---|---|
| **RN04** | todo produto pertence a exatamente uma categoria |
| **RN08** | o item do pedido guarda o preço praticado no dia da venda |
| **RN10** | toda movimentação de estoque tem data **e** hora |
| **RN11** | o saldo de estoque nunca fica negativo |
| **RN13** | um pagamento por pedido |
| **RN16** | um supervisor direto por funcionário |
| **RN17** | a especialização de pessoa é total e disjunta |
| **RN18** | o mesmo produto não se repete no mesmo pedido |
| **RN19** | pedido cancelado não conta como venda |

A RN17 merece um registro honesto: a estrutura garante que cliente e
funcionário existam apenas como especializações de pessoa, mas **não**
garante nem a totalidade nem a exclusividade. Nada no esquema impede
cadastrar uma pessoa que não apareça em nenhuma das duas, ou que apareça
nas duas. Fazer o banco cumprir isso exigiria um atributo discriminador com
restrição de verificação, ou gatilhos. Hoje a regra é mantida pela
aplicação.

---

## Uso de inteligência artificial

A equipe utilizou ferramentas de inteligência artificial generativa como
apoio ao longo do desenvolvimento deste trabalho.

O uso se deu em caráter auxiliar, em atividades de pesquisa, revisão,
estruturação de texto e apoio à escrita de código. Todo o conteúdo
produzido foi revisado, testado e validado pelos integrantes, que respondem
integralmente pelas decisões de modelagem, pelas regras de negócio adotadas
e pelo funcionamento do que foi entregue.

As ferramentas foram empregadas como instrumento de produtividade e
aprendizado, sem substituir a compreensão do conteúdo da disciplina, que
permanece sendo de responsabilidade da equipe.
