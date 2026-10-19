# Projeto Final — Laboratório de Banco de Dados

Distribuidora de Bebidas · MySQL · UCB 2026/2

**Para rodar, veja o `COMO-RODAR.md`.** São dois passos, e precisa apenas
de MySQL 8.0 e de um Java já instalados. Este arquivo é o índice do que
vem no pacote.

---

## O que tem em cada lugar

### Na raiz

| Arquivo | O que é |
|---|---|
| `COMO-RODAR.md` | os dois passos para subir o banco e abrir a aplicação |
| `EXECUTAR.bat` | abre a aplicação sem precisar de IDE |
| `distribuidora-app.jar` | a aplicação compilada |
| `lib/` | onde entra o driver do MySQL (veja o `lib/LEIA.txt`) |

### `sql/`

| Arquivo | O que faz |
|---|---|
| `banco-completo.sql` | **os três abaixo num arquivo só**, mais o usuário da aplicação |
| `01_ddl.sql` | estrutura: o banco e as treze tabelas |
| `02_carga.sql` | dados: 1.271 registros |
| `03_consultas.sql` | as quinze consultas da Etapa 1 |
| `04_etapa2.sql` | tabela de usuários e as duas visões da Etapa 2 |

Os quatro primeiros são a entrega propriamente dita, na ordem em que
foram desenvolvidos e documentados no relatório. O `banco-completo.sql`
não acrescenta nada: existe só para subir tudo de uma vez em máquina
onde nada foi rodado ainda.

O `03_consultas.sql` não altera nada, só lê. Vale rodar depois da carga
para conferir que ficou boa.

### `app/`

O projeto Java, para abrir no NetBeans ou em qualquer IDE com Maven. É a
pasta que tem o `pom.xml`. O `README-app.md`, dentro dela, é a
documentação técnica: a transação, o nível de isolamento, a tradução de
erros e a demonstração de resistência a injeção de SQL.

### `documentacao/`

O que foi entregue na Etapa 1: relatório em PDF e em Word, o dicionário
de dados em arquivo separado, o modelo conceitual, o modelo lógico e o
arquivo `.mwb` do Workbench que gerou os diagramas.

---

## Como foi verificado

A aplicação compila sem erro, com 35 classes. O `banco-completo.sql` foi
executado inteiro e conferido: 167 instruções sem erro, as catorze
contagens de tabela batendo, as duas visões respondendo, o usuário
gravado com sal de 32 e hash de 64 caracteres, e nenhum saldo de estoque
negativo.

Essa execução foi feita fora do MySQL, por indisponibilidade dele no
ambiente de desenvolvimento, traduzindo o script para outro SGBD. Ela
pega erro de sintaxe, tabela ou coluna inexistente, ordem errada de
criação, chave duplicada, chave estrangeira órfã e `CHECK` violado — não
pega o que é específico do MySQL. **É por isso que o
`banco-completo.sql` imprime a tabela de conferência no fim:** ela
repete a mesma checagem rodando no MySQL de verdade, na máquina onde o
banco for subir.

---

## O que falta, para não esquecer

Depois de rodar no MySQL, três coisas precisam ser registradas no
relatório da Etapa 2:

- **B2** — a demonstração de injeção de SQL: a entrada usada e o
  resultado obtido
- **B3** — a transação passo a passo, com `BEGIN`, os comandos e o
  `COMMIT` ou `ROLLBACK`
- **B3** — o experimento de concorrência, com duas sessões abertas ao
  mesmo tempo sobre o mesmo produto

O roteiro das duas primeiras está no fim do `COMO-RODAR.md`.

Os artefatos **B4** a **B8** são dos outros integrantes: estudos de plano
de execução, perfis de acesso e auditoria, projeto físico e o relatório
final.
