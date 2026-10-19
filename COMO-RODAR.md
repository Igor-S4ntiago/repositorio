# Como rodar

Dois passos. Precisa de MySQL 8.0 e de um Java instalados, e nada além
disso — nenhuma instalação é necessária.

---

## Passo 1 — Subir o banco

Abra o **MySQL Workbench**, conecte na instância local e importe **um
arquivo só**:

```
sql/banco-completo.sql
```

Pelo menu: **File → Open SQL Script**, escolha o arquivo, e clique no
raio ⚡.

Leva menos de um minuto. No fim ele imprime uma tabela de conferência:

| conferência | esperado |
|---|---|
| versão do MySQL | 8.0.16 ou maior |
| produtos | 60 |
| pedidos | 70 |
| movimentações de estoque | 374 |
| usuário da aplicação | 1 (admin) |

Se as cinco linhas batem, o banco está pronto. Esse arquivo é a junção
dos três scripts do projeto — estrutura, dados e objetos da Etapa 2 — e
já cria o usuário da aplicação, então não há mais nada a rodar.

> O arquivo começa apagando o banco `distribuidora_bebidas`, se ele
> existir. É o que permite importar de novo sem dar erro. Se houver um
> banco com esse nome que importe conservar, renomeie antes.

## Passo 2 — Abrir a aplicação

Duplo clique em **`EXECUTAR.bat`**.

Na primeira vez aparece uma janela pedindo o acesso ao MySQL. Os campos
já vêm preenchidos; só a senha precisa ser digitada — a mesma senha do
`root` usada no Workbench. Clique em **Testar e continuar**.

O botão testa a conexão antes de seguir. Se a senha estiver errada, ele
diz ali mesmo e você corrige na hora. Quando funciona, ele grava a
resposta e nas próximas vezes não pergunta mais.

Depois vem a tela de login da aplicação:

```
usuário: admin
senha:   senha123
```

Pronto.

---

## Se o EXECUTAR.bat reclamar

**"o driver do MySQL não está na pasta lib"** — falta um arquivo, que
não vem no pacote por ser software da Oracle. As instruções de onde
baixar estão em `lib/LEIA.txt`. É um arquivo de 2 MB, baixado uma vez.

**"não encontrei o Java nesta máquina"** — o `.bat` procura no PATH e nos
lugares usuais de instalação. Se o Java existe mas está em outro lugar,
o NetBeans sabe onde: **Tools → Java Platforms** mostra o caminho. A
própria mensagem do `.bat` traz o comando a rodar com ele.

---

## Rodando pelo NetBeans

O jeito acima não usa IDE nenhuma. Mas se a ideia for mostrar o código,
ou rodar de dentro do NetBeans:

**File → Open Project**, e escolha a pasta **`app`** — a que tem o
`pom.xml`. O NetBeans reconhece projeto Maven sem configuração.

**Antes de rodar, compile uma vez:** clique com o botão direito no
projeto e escolha **Clean and Build**. É nessa hora que o Maven baixa o
driver do MySQL e gera as classes. Leva alguns segundos na primeira vez,
e precisa de internet só aí.

Depois é **Run → Run Project**, ou F6. A classe principal é
`br.ucb.distribuidora.Main`, já declarada no `pom.xml`.

> Se aparecer a janela **Select Main Class for Execution** dizendo
> *"No main classes found"*, é sinal de que o projeto ainda não foi
> compilado: o NetBeans procura a classe principal nas classes geradas,
> não no código-fonte. Cancele, faça **Clean and Build** e rode de novo.
>
> Se o **Clean and Build** falhar com mensagem de dependência não
> resolvida, é a máquina sem acesso ao repositório do Maven. Nesse caso
> use o `EXECUTAR.bat`, que não depende de download nenhum.

Nesse caminho o `config.properties` fica dentro da pasta `app`, não na
raiz — quem grava é a própria janela de conexão, então não há o que
configurar à mão.

---

## Para mostrar na apresentação

**A transação, e o que acontece quando ela falha.** Na aba *Nova venda*,
peça 9999 unidades de qualquer produto. Aparece a mensagem de estoque
insuficiente, e nada é gravado. Para provar que o banco continuou
íntegro, rode no Workbench a consulta `V01` do `03_consultas.sql`: ela
compara o saldo de cada produto com a soma das suas movimentações e tem
de continuar voltando vazia.

Há também a caixa *Provocar falha no fim da transação*. Com ela marcada,
os cinco passos da venda são executados e só então o erro acontece — o
que mostra o `ROLLBACK` desfazendo até o que já havia sido gravado.

**Resistência a injeção de SQL.** Na mesma aba, no campo *Filtrar
produto*, digite:

```
' OR '1'='1
```

A lista fica vazia. O texto foi procurado como nome de produto, não
executado como comando.
