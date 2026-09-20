[README.md](https://github.com/user-attachments/files/32444723/README.md)
# Sistema de Gestão para Distribuidora de Bebidas

Equipe

* Igor Santiago Pereira da Silva
* João Arantes Rodrigues
* Jander Matheus Correia de Lima Pinto

## Domínio

Uma distribuidora de bebidas. O banco cobre o cadastro de clientes,
funcionários, produtos, categorias e fornecedores, a venda por pedidos, o
controle de estoque com histórico datado de movimentações, o pagamento e a
entrega.

O modelo tem 13 relações e 58 atributos. Inclui uma especialização
(`pessoa` em `cliente` e `funcionario`), um autorrelacionamento (a hierarquia
de supervisão em `funcionario`), dois relacionamentos N:N com atributo
próprio (`produto\_fornecedor` e `item\_pedido`) e uma entidade identificada
por dependência (`item\_pedido`).

## Estrutura do repositório

```
.
├── README.md
├── docs/
│   ├── relatorio-etapa1.pdf      relatório único, reunindo os artefatos A1 a A5
│   ├── relatorio-etapa1.docx     o mesmo documento, editável
│   ├── mer-conceitual.pdf        modelo conceitual em notação pé de galinha
│   ├── mer-conceitual.drawio     arquivo-fonte do diagrama conceitual
│   ├── mer-conceitual.mwb        arquivo-fonte do MySQL Workbench
│   ├── modelo-logico.pdf         esquema relacional
│   └── dicionario-dados.pdf      dicionário no formato do Anexo A
└── sql/
    ├── 01\_ddl.sql                criação do banco e das treze tabelas
    ├── 02\_carga.sql              carga de 1.271 registros fictícios
    └── 03\_consultas.sql          quinze consultas e três conferências
```

## Pré-requisitos

* **MySQL 8.0.16 ou superior.** A versão importa: abaixo de 8.0.16 o MySQL
aceita a sintaxe das restrições `CHECK` e as ignora silenciosamente, o que
desativaria as doze restrições de domínio do modelo.
* Cliente de linha de comando `mysql` ou o MySQL Workbench.

## Como executar

Os três scripts devem rodar nesta ordem, em uma base limpa:

```bash
mysql -u SEU\_USUARIO -p < sql/01\_ddl.sql
mysql -u SEU\_USUARIO -p < sql/02\_carga.sql
mysql -u SEU\_USUARIO -p < sql/03\_consultas.sql
```

Se o banco `distribuidora\_bebidas` já existir de uma execução anterior,
apague-o antes:

```sql
DROP DATABASE IF EXISTS distribuidora\_bebidas;
```

O `02\_carga.sql` começa com comandos `DELETE` em ordem inversa à das
dependências, de modo que ele pode ser reexecutado sobre a mesma base sem
erro de integridade referencial.

## O que cada script faz

**`01\_ddl.sql`** — cria o banco e as treze tabelas. Declara 13 chaves
primárias (`pk\_`), 8 restrições de unicidade (`uq\_`), 14 chaves estrangeiras
(`fk\_`), 12 restrições de verificação (`ck\_`) e 8 índices (`idx\_`). Toda
chave estrangeira traz `ON DELETE` e `ON UPDATE` explícitos.

**`02\_carga.sql`** — insere 1.271 registros fictícios, na ordem das
dependências. A carga simula a operação em ordem cronológica: as entradas de
compra são lançadas antes das saídas de venda, de modo que nenhum saldo fica
negativo e `estoque.quantidade\_atual` é exatamente a soma das entradas menos
as saídas. Inclui casos de contorno propositais: cadastros sem telefone ou
e-mail, cliente sem endereço, clientes sem pedido, funcionários desligados,
categorias sem produto, produtos sem fornecedor, produtos zerados, pedidos
cancelados e entregas sem responsável.

Volume por tabela:

|Tabela|Linhas|Tabela|Linhas|
|-|-|-|-|
|`pessoa`|105|`pedido`|70|
|`cliente`|63|`item\_pedido`|199|
|`funcionario`|42|`pagamento`|70|
|`categoria`|40|`entrega`|42|
|`fornecedor`|40|`estoque`|60|
|`produto`|60|`movimentacao\_estoque`|374|
|`produto\_fornecedor`|106|**Total**|**1.271**|

**`03\_consultas.sql`** — quinze consultas comentadas, cada uma precedida da
pergunta de negócio que responde: C01 a C05 básicas, C06 a C10 com junções e
agregação, C11 a C15 avançadas (subconsulta correlacionada, `EXISTS` com
`NOT EXISTS`, expressões de tabela comuns, consulta recursiva sobre a
hierarquia de supervisão e funções de janela para a curva ABC).

No fim do arquivo há três consultas de conferência, `V01` a `V03`, fora da
contagem das quinze. Elas auditam a coerência da carga e devem retornar
sempre nenhuma linha:

* `V01` compara o saldo em `estoque` com a soma das movimentações;
* `V02` procura pedidos sem pagamento;
* `V03` procura entregas com situação e data incoerentes.

