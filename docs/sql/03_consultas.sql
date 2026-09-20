-- =========================================================
-- PROJETO: Sistema de Gestão para Distribuidora de Bebidas
-- ETAPA: A8 - CONSULTAS
-- ARQUIVO: 03_consultas.sql
-- SGBD: MySQL 8+
--
-- Execute depois do 01_ddl.sql e do 02_carga.sql.
--
-- São 15 consultas divididas em três blocos, como pede o enunciado:
--   C01 a C05 - básicas (projeção, seleção, ordenação e tratamento de NULL)
--   C06 a C10 - junções e agregação
--   C11 a C15 - avançadas (subconsulta correlacionada, EXISTS, CTE,
--               consulta recursiva e função de janela)
--
-- Antes de cada consulta está a pergunta de negócio que ela responde e a
-- regra de negócio relacionada, quando existe.
--
-- No fim do arquivo há três consultas de conferência, fora da contagem
-- das 15, usadas para verificar se a carga ficou consistente.
-- =========================================================

USE distribuidora_bebidas;


-- =========================================================
-- BLOCO 1 - CONSULTAS BÁSICAS
-- =========================================================

-- ---------------------------------------------------------
-- C01
-- Pergunta: qual é a tabela de preços da distribuidora, do produto mais
-- caro para o mais barato?
-- Recursos: projeção de colunas e ordenação.
-- ---------------------------------------------------------
SELECT
    idproduto,
    nome,
    unidade_medida,
    preco_venda
FROM produto
ORDER BY preco_venda DESC, nome;


-- ---------------------------------------------------------
-- C02
-- Pergunta: quais produtos da linha de cerveja estão cadastrados?
-- Recursos: filtro com LIKE.
-- ---------------------------------------------------------
SELECT
    idproduto,
    nome,
    preco_venda
FROM produto
WHERE nome LIKE 'Cerveja%'
ORDER BY nome;


-- ---------------------------------------------------------
-- C03
-- Pergunta: quais pedidos foram feitos no primeiro trimestre de 2026?
-- Recursos: filtro por faixa de datas com BETWEEN.
-- ---------------------------------------------------------
SELECT
    idpedido,
    data_pedido,
    status,
    cliente_pessoa_idpessoa
FROM pedido
WHERE data_pedido BETWEEN '2026-01-01 00:00:00' AND '2026-03-31 23:59:59'
ORDER BY data_pedido;


-- ---------------------------------------------------------
-- C04
-- Pergunta: quem está na equipe de rua e de armazém hoje, ou seja, os
-- funcionários ativos nesses cargos?
-- Recursos: filtro com IN combinado com outra condição.
-- Regra relacionada: RN02.
-- ---------------------------------------------------------
SELECT
    f.pessoa_idpessoa,
    p.nome,
    f.cargo,
    f.data_admissao
FROM funcionario f
JOIN pessoa p ON p.idpessoa = f.pessoa_idpessoa
WHERE f.cargo IN ('Motorista', 'Estoquista', 'Conferente')
  AND f.ativo = 1
ORDER BY f.cargo, p.nome;


-- ---------------------------------------------------------
-- C05
-- Pergunta: quais cadastros de pessoa estão incompletos, sem telefone ou
-- sem e-mail, para a equipe entrar em contato e completar?
-- Recursos: tratamento de valores nulos com IS NULL, COALESCE e CASE.
-- Regra relacionada: RN01.
-- ---------------------------------------------------------
SELECT
    p.idpessoa,
    p.nome,
    COALESCE(p.telefone, 'não informado') AS telefone,
    COALESCE(p.email, 'não informado')    AS email,
    CASE
        WHEN p.telefone IS NULL AND p.email IS NULL THEN 'sem nenhum contato'
        WHEN p.telefone IS NULL                     THEN 'falta telefone'
        ELSE                                             'falta e-mail'
    END AS pendencia
FROM pessoa p
WHERE p.telefone IS NULL
   OR p.email IS NULL
ORDER BY pendencia, p.nome;


-- =========================================================
-- BLOCO 2 - JUNÇÕES E AGREGAÇÃO
-- =========================================================

-- ---------------------------------------------------------
-- C06
-- Pergunta: quanto cada categoria de bebida faturou, considerando só os
-- pedidos que não foram cancelados?
-- Recursos: junção de quatro tabelas, agregação e agrupamento.
-- Regras relacionadas: RN08 (vale o preço praticado na venda) e RN19
-- (pedido cancelado não conta como venda).
-- ---------------------------------------------------------
SELECT
    c.idcategoria,
    c.nome                                          AS categoria,
    COUNT(DISTINCT i.pedido_idpedido)               AS pedidos,
    SUM(i.quantidade)                               AS unidades_vendidas,
    ROUND(SUM(i.quantidade * i.preco_unitario), 2)  AS faturamento
FROM categoria c
JOIN produto     p ON p.categoria_idcategoria = c.idcategoria
JOIN item_pedido i ON i.produto_idproduto     = p.idproduto
JOIN pedido      d ON d.idpedido              = i.pedido_idpedido
WHERE d.status <> 'CANCELADO'
GROUP BY c.idcategoria, c.nome
ORDER BY faturamento DESC;


-- ---------------------------------------------------------
-- C07
-- Pergunta: quais produtos estão parados, ou seja, nunca apareceram em
-- nenhum pedido?
-- Recursos: junção externa à esquerda com teste de nulo.
-- ---------------------------------------------------------
SELECT
    p.idproduto,
    p.nome,
    c.nome            AS categoria,
    p.preco_venda,
    e.quantidade_atual
FROM produto p
JOIN      categoria   c ON c.idcategoria       = p.categoria_idcategoria
LEFT JOIN estoque     e ON e.produto_idproduto = p.idproduto
LEFT JOIN item_pedido i ON i.produto_idproduto = p.idproduto
WHERE i.produto_idproduto IS NULL
ORDER BY p.nome;


-- ---------------------------------------------------------
-- C08
-- Pergunta: quem são os clientes recorrentes, com três ou mais pedidos
-- válidos, e qual o ticket médio de cada um?
-- Recursos: agrupamento com filtro sobre o agregado (HAVING).
-- Regra relacionada: RN07.
-- ---------------------------------------------------------
SELECT
    ps.idpessoa,
    ps.nome,
    COUNT(DISTINCT d.idpedido)                                  AS pedidos,
    ROUND(SUM(i.quantidade * i.preco_unitario), 2)              AS total_comprado,
    ROUND(SUM(i.quantidade * i.preco_unitario)
          / COUNT(DISTINCT d.idpedido), 2)                      AS ticket_medio
FROM cliente     cl
JOIN pessoa      ps ON ps.idpessoa = cl.pessoa_idpessoa
JOIN pedido      d  ON d.cliente_pessoa_idpessoa = cl.pessoa_idpessoa
JOIN item_pedido i  ON i.pedido_idpedido = d.idpedido
WHERE d.status <> 'CANCELADO'
GROUP BY ps.idpessoa, ps.nome
HAVING COUNT(DISTINCT d.idpedido) >= 3
ORDER BY total_comprado DESC;


-- ---------------------------------------------------------
-- C09
-- Pergunta: como está o desempenho dos motoristas nas entregas, incluindo
-- os que ainda não receberam nenhuma rota?
-- Recursos: junção externa a partir de funcionário, contagem condicional
-- e média de atraso em dias.
-- Regras relacionadas: RN14 e RN15.
-- ---------------------------------------------------------
SELECT
    f.pessoa_idpessoa,
    ps.nome,
    COUNT(e.identrega)                                          AS rotas,
    SUM(CASE WHEN e.status_entrega = 'ENTREGUE' THEN 1 ELSE 0 END)
                                                                AS concluidas,
    SUM(CASE WHEN e.status_entrega = 'EM_ROTA'  THEN 1 ELSE 0 END)
                                                                AS em_rota,
    ROUND(AVG(DATEDIFF(e.data_entrega, e.data_prevista)), 1)    AS media_dias_atraso
FROM funcionario f
JOIN      pessoa  ps ON ps.idpessoa = f.pessoa_idpessoa
LEFT JOIN entrega e  ON e.funcionario_pessoa_idpessoa = f.pessoa_idpessoa
WHERE f.cargo = 'Motorista'
GROUP BY f.pessoa_idpessoa, ps.nome
ORDER BY rotas DESC, ps.nome;


-- ---------------------------------------------------------
-- C10
-- Pergunta: quanto de dinheiro está parado em estoque, separado por
-- categoria?
-- Recursos: junção de três tabelas com agregação e cálculo derivado.
-- Regra relacionada: RN03.
-- ---------------------------------------------------------
SELECT
    c.nome                                                  AS categoria,
    COUNT(p.idproduto)                                      AS itens_cadastrados,
    SUM(e.quantidade_atual)                                 AS garrafas_em_estoque,
    ROUND(SUM(e.quantidade_atual * p.preco_venda), 2)       AS valor_imobilizado
FROM categoria c
JOIN produto   p ON p.categoria_idcategoria = c.idcategoria
JOIN estoque   e ON e.produto_idproduto     = p.idproduto
GROUP BY c.idcategoria, c.nome
ORDER BY valor_imobilizado DESC;


-- =========================================================
-- BLOCO 3 - CONSULTAS AVANÇADAS
-- =========================================================

-- ---------------------------------------------------------
-- C11
-- Pergunta: quais produtos custam mais caro que a média da própria
-- categoria? São os candidatos a revisão de preço.
-- Recursos: subconsulta correlacionada no WHERE e no SELECT.
-- ---------------------------------------------------------
SELECT
    p.idproduto,
    p.nome,
    c.nome                                  AS categoria,
    p.preco_venda,
    (SELECT ROUND(AVG(m.preco_venda), 2)
       FROM produto m
      WHERE m.categoria_idcategoria = p.categoria_idcategoria)
                                            AS media_da_categoria
FROM produto   p
JOIN categoria c ON c.idcategoria = p.categoria_idcategoria
WHERE p.preco_venda > (
        SELECT AVG(m.preco_venda)
          FROM produto m
         WHERE m.categoria_idcategoria = p.categoria_idcategoria)
ORDER BY c.nome, p.preco_venda DESC;


-- ---------------------------------------------------------
-- C12
-- Pergunta: quais clientes já compraram cerveja mas nunca levaram vinho?
-- É a lista para a ação de venda cruzada da equipe comercial.
-- Recursos: EXISTS combinado com NOT EXISTS.
-- ---------------------------------------------------------
SELECT
    ps.idpessoa,
    ps.nome,
    COALESCE(ps.telefone, ps.email, 'sem contato') AS contato
FROM cliente cl
JOIN pessoa  ps ON ps.idpessoa = cl.pessoa_idpessoa
WHERE EXISTS (
        SELECT 1
          FROM pedido      d
          JOIN item_pedido i ON i.pedido_idpedido       = d.idpedido
          JOIN produto     p ON p.idproduto             = i.produto_idproduto
          JOIN categoria   c ON c.idcategoria           = p.categoria_idcategoria
         WHERE d.cliente_pessoa_idpessoa = cl.pessoa_idpessoa
           AND d.status <> 'CANCELADO'
           AND c.nome LIKE 'Cerveja%')
  AND NOT EXISTS (
        SELECT 1
          FROM pedido      d
          JOIN item_pedido i ON i.pedido_idpedido       = d.idpedido
          JOIN produto     p ON p.idproduto             = i.produto_idproduto
          JOIN categoria   c ON c.idcategoria           = p.categoria_idcategoria
         WHERE d.cliente_pessoa_idpessoa = cl.pessoa_idpessoa
           AND d.status <> 'CANCELADO'
           AND c.nome LIKE 'Vinho%')
ORDER BY ps.nome;


-- ---------------------------------------------------------
-- C13
-- Pergunta: quais produtos precisam ser recomprados agora? São aqueles
-- cujo estoque atual não dura o suficiente para aguentar o prazo de
-- entrega do fornecedor mais lento, com uma folga de 15 dias.
-- O ritmo de venda é calculado sobre o período coberto pela base.
-- Recursos: três expressões de tabela comuns (CTE), divisão protegida
-- contra zero e comparação entre dois indicadores calculados.
-- Regras relacionadas: RN06, RN09 e RN11.
-- ---------------------------------------------------------
WITH periodo AS (
    SELECT
        DATEDIFF(MAX(data_pedido), MIN(data_pedido)) AS dias
    FROM pedido
    WHERE status <> 'CANCELADO'
),
venda_diaria AS (
    SELECT
        i.produto_idproduto                         AS idproduto,
        SUM(i.quantidade)                           AS total_vendido,
        SUM(i.quantidade) * 1.0 / (SELECT dias FROM periodo) AS media_dia
    FROM item_pedido i
    JOIN pedido d ON d.idpedido = i.pedido_idpedido
    WHERE d.status <> 'CANCELADO'
    GROUP BY i.produto_idproduto
),
prazo_fornecedor AS (
    SELECT
        produto_idproduto        AS idproduto,
        MAX(prazo_fornecimento)  AS maior_prazo
    FROM produto_fornecedor
    GROUP BY produto_idproduto
)
SELECT
    p.idproduto,
    p.nome,
    e.quantidade_atual,
    v.total_vendido,
    ROUND(v.media_dia, 2)                           AS media_por_dia,
    ROUND(e.quantidade_atual / v.media_dia, 1)      AS dias_de_cobertura,
    z.maior_prazo                                   AS prazo_do_fornecedor,
    z.maior_prazo + 15                              AS ponto_de_recompra
FROM venda_diaria      v
JOIN produto           p ON p.idproduto         = v.idproduto
JOIN estoque           e ON e.produto_idproduto = p.idproduto
JOIN prazo_fornecedor  z ON z.idproduto         = p.idproduto
WHERE v.media_dia > 0
  AND e.quantidade_atual / v.media_dia < z.maior_prazo + 15
ORDER BY dias_de_cobertura;


-- ---------------------------------------------------------
-- C14
-- Pergunta: como fica desenhado o organograma da distribuidora, do
-- gerente geral até a equipe operacional?
-- Recursos: consulta recursiva sobre o autorrelacionamento de
-- funcionário, montando o nível e o caminho completo da hierarquia.
-- Regra relacionada: RN16.
-- ---------------------------------------------------------
WITH RECURSIVE organograma AS (
    -- Âncora: quem não tem supervisor está no topo.
    SELECT
        f.pessoa_idpessoa,
        ps.nome,
        f.cargo,
        1                           AS nivel,
        CAST(ps.nome AS CHAR(500))  AS caminho
    FROM funcionario f
    JOIN pessoa     ps ON ps.idpessoa = f.pessoa_idpessoa
    WHERE f.idsupervisor IS NULL

    UNION ALL

    -- Passo recursivo: desce um nível a cada rodada.
    SELECT
        f.pessoa_idpessoa,
        ps.nome,
        f.cargo,
        o.nivel + 1,
        CAST(CONCAT(o.caminho, ' > ', ps.nome) AS CHAR(500))
    FROM funcionario f
    JOIN pessoa      ps ON ps.idpessoa           = f.pessoa_idpessoa
    JOIN organograma o  ON o.pessoa_idpessoa     = f.idsupervisor
)
SELECT
    nivel,
    cargo,
    nome,
    caminho
FROM organograma
ORDER BY caminho;


-- ---------------------------------------------------------
-- C15
-- Pergunta: quais produtos formam a curva ABC do faturamento? A classe A
-- é o grupo que responde pelos primeiros 80% da receita.
-- Recursos: funções de janela (SUM OVER com soma acumulada e total
-- geral) e classificação por faixa.
-- ---------------------------------------------------------
WITH receita AS (
    SELECT
        p.idproduto,
        p.nome,
        ROUND(SUM(i.quantidade * i.preco_unitario), 2) AS faturamento
    FROM item_pedido i
    JOIN pedido  d ON d.idpedido  = i.pedido_idpedido
    JOIN produto p ON p.idproduto = i.produto_idproduto
    WHERE d.status <> 'CANCELADO'
    GROUP BY p.idproduto, p.nome
),
acumulado AS (
    SELECT
        idproduto,
        nome,
        faturamento,
        ROW_NUMBER() OVER (ORDER BY faturamento DESC)           AS posicao,
        SUM(faturamento) OVER (ORDER BY faturamento DESC
                               ROWS BETWEEN UNBOUNDED PRECEDING
                                        AND CURRENT ROW)        AS soma_ate_aqui,
        SUM(faturamento) OVER ()                                AS total_geral
    FROM receita
)
SELECT
    posicao,
    idproduto,
    nome,
    faturamento,
    ROUND(100.0 * soma_ate_aqui / total_geral, 1) AS percentual_acumulado,
    CASE
        WHEN 100.0 * soma_ate_aqui / total_geral <= 80 THEN 'A'
        WHEN 100.0 * soma_ate_aqui / total_geral <= 95 THEN 'B'
        ELSE                                                'C'
    END AS classe
FROM acumulado
ORDER BY posicao;


-- =========================================================
-- CONFERÊNCIAS
-- Não contam entre as 15 consultas pedidas. Servem para checar se a
-- carga ficou coerente. As três devem retornar nenhuma linha.
-- =========================================================

-- V01 - O saldo gravado em estoque tem de ser igual às entradas menos as
--       saídas registradas na movimentação (RN09 e RN11).
SELECT
    e.idestoque,
    e.produto_idproduto,
    e.quantidade_atual,
    COALESCE(SUM(CASE WHEN m.tipo = 'ENTRADA' THEN m.quantidade
                      ELSE -m.quantidade END), 0) AS saldo_calculado
FROM estoque e
LEFT JOIN movimentacao_estoque m ON m.estoque_idestoque = e.idestoque
GROUP BY e.idestoque, e.produto_idproduto, e.quantidade_atual
HAVING e.quantidade_atual <> saldo_calculado;


-- V02 - Nenhum pedido pode ficar sem pagamento associado (RN13).
SELECT
    d.idpedido,
    d.status
FROM pedido d
WHERE NOT EXISTS (SELECT 1
                    FROM pagamento g
                   WHERE g.pedido_idpedido = d.idpedido);


-- V03 - Entrega marcada como concluída precisa ter data de entrega, e
--       entrega não concluída não pode ter data preenchida (RN14).
SELECT
    identrega,
    status_entrega,
    data_prevista,
    data_entrega
FROM entrega
WHERE (status_entrega =  'ENTREGUE' AND data_entrega IS NULL)
   OR (status_entrega <> 'ENTREGUE' AND data_entrega IS NOT NULL);
