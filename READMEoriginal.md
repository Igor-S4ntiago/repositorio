# Sistema de Gestão para Distribuidora de Bebidas

Projeto Final da disciplina **Laboratório de Banco de Dados** (GPE17M40083) —
Bacharelado em Engenharia de Software, Universidade Católica de Brasília,
2026/2. Docente: Samuel Novais Moura Júnior.

**Etapa 1** — modelagem e implementação física. 
**Etapa 2** — aplicação, transações, concorrência e controle de acesso.

## Equipe

- Igor Santiago Pereira da Silva
- João Arantes Rodrigues
- Jander Matheus Correia de Lima Pinto

## Domínio

Uma distribuidora de bebidas. O banco cobre o cadastro de clientes,
funcionários, produtos, categorias e fornecedores, a venda por pedidos, o
controle de estoque com histórico datado de movimentações, o pagamento e a
entrega.

O modelo tem 13 relações e 58 atributos. Inclui uma especialização
(`pessoa` em `cliente` e `funcionario`), um autorrelacionamento (a hierarquia
de supervisão em `funcionario`), dois relacionamentos N:N com atributo
próprio, mapeados como entidades associativas (`produto_fornecedor` e
`item_pedido`), e uma entidade fraca, identificada por dependência
(`movimentacao_estoque`, que só se distingue pelo estoque a que pertence
mais a data e hora em que ocorreu).

## Estrutura do repositório

```
.
├── README.md
├── docs/
│   ├── relatorio-etapa1.pdf     relatório único, reunindo os artefatos A1 a A5
│   ├── mer-conceitual.pdf       modelo entidade-relacionamento
│   ├── mer-conceitual.mwb       arquivo-fonte do diagrama (MySQL Workbench)
│   ├── modelo-logico.pdf        esquema relacional
│   └── dicionario-dados.pdf     dicionário no formato do Anexo A
└── sql/
    ├── 01_ddl.sql               criação do banco e das treze tabelas
    ├── 02_carga.sql             carga de 1.271 registros fictícios
    └── 03_consultas.sql         quinze consultas e três conferências
```

## Pré-requisitos

- **MySQL 8.0.16 ou superior.** A versão importa: abaixo de 8.0.16 o MySQL
  aceita a sintaxe das restrições `CHECK` e as ignora silenciosamente, o que
  desativaria as doze restrições de domínio do modelo.
- Cliente de linha de comando `mysql` ou o MySQL Workbench.

## Como executar

Os três scripts devem rodar nesta ordem, em uma base limpa:

```bash
mysql -u SEU_USUARIO -p < sql/01_ddl.sql
mysql -u SEU_USUARIO -p < sql/02_carga.sql
mysql -u SEU_USUARIO -p < sql/03_consultas.sql
```

Se o banco já existir de uma execução anterior, apague antes:

```sql
DROP DATABASE IF EXISTS distribuidora_bebidas;
```

O `02_carga.sql` começa com comandos `DELETE` em ordem inversa à das
dependências, de modo que pode ser reexecutado sobre a mesma base sem erro
de integridade referencial.

## O que cada script faz

### `01_ddl.sql`

Cria o banco `distribuidora_bebidas` e as treze tabelas, na ordem das
dependências. Declara 13 chaves primárias (`pk_`), 8 restrições de unicidade
(`uq_`), 14 chaves estrangeiras (`fk_`), 12 restrições de verificação
(`ck_`) e 8 índices (`idx_`). Toda chave estrangeira traz `ON DELETE` e
`ON UPDATE` explícitos.

### `02_carga.sql`

Insere 1.271 registros fictícios. A coluna de preço de compra em
`produto_fornecedor` chama-se `preco_compra`; o nome `preco_comprar`, que
constava de uma versão anterior do script, foi corrigido. Nomes, CPF, CNPJ, telefones e endereços
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

No fim do arquivo há três consultas de conferência, `V01` a `V03`, fora da
contagem das quinze. Elas auditam a coerência da carga e devem retornar
sempre nenhuma linha:

- `V01` compara o saldo em `estoque` com a soma das movimentações;
- `V02` procura pedidos sem pagamento associado;
- `V03` procura entregas com situação e data incoerentes.

## Conferência da carga

A consulta `V01`, no fim de `03_consultas.sql`, é a verificação mais
importante do conjunto: ela compara, para cada produto, o saldo gravado em
`estoque.quantidade_atual` com a soma das entradas menos as saídas
registradas em `movimentacao_estoque`.

O saldo é um valor derivado, mantido por decisão de desempenho — calcular a
posição por agregação a cada leitura custaria percorrer todo o histórico do
produto. A `V01` é o controle dessa redundância, e o resultado esperado é
nenhuma linha. Na Etapa 2 ela passou a ter um segundo uso: é a prova de que
o banco permaneceu íntegro depois das demonstrações de falha de transação.

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
[README.md](https://github.com/user-attachments/files/33644884/README.md)
