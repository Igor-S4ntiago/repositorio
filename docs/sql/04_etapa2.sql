-- =========================================================
-- PROJETO: Sistema de Gestão para Distribuidora de Bebidas
-- ETAPA 2 - objetos de banco exigidos pela aplicação
-- ARQUIVO: 04_etapa2.sql
-- SGBD: MySQL 8+
--
-- Execute depois do 01_ddl.sql e do 02_carga.sql.
--
-- Este script acrescenta ao banco da Etapa 1 o que a aplicação precisa:
--   1. a tabela de usuários da aplicação, com senha em hash e sal (B5);
--   2. as visões que alimentam as telas de relatório (B1).
-- =========================================================

USE distribuidora_bebidas;

-- =========================================================
-- USUARIO
-- Login da aplicação. Não se confunde com os perfis de acesso do
-- próprio MySQL, criados com GRANT e REVOKE: aqui é quem opera o
-- sistema, lá é quem se conecta ao banco.
--
-- A senha nunca é guardada em texto claro. Gravamos o resultado do
-- PBKDF2 e o sal aleatório usado em cada senha, ambos em hexadecimal.
-- =========================================================
DROP TABLE IF EXISTS usuario;

CREATE TABLE usuario (
    idusuario INT NOT NULL AUTO_INCREMENT,
    login VARCHAR(30) NOT NULL,
    senha_hash CHAR(64) NOT NULL,
    senha_sal CHAR(32) NOT NULL,
    perfil VARCHAR(20) NOT NULL,
    ativo TINYINT NOT NULL DEFAULT 1,
    funcionario_pessoa_idpessoa INT,

    CONSTRAINT pk_usuario PRIMARY KEY (idusuario),

    CONSTRAINT uq_usuario_login UNIQUE (login),

    CONSTRAINT fk_usuario_funcionario
        FOREIGN KEY (funcionario_pessoa_idpessoa)
        REFERENCES funcionario(pessoa_idpessoa)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT ck_usuario_perfil
        CHECK (perfil IN ('ADMIN', 'VENDEDOR', 'ESTOQUISTA')),

    CONSTRAINT ck_usuario_ativo
        CHECK (ativo IN (0, 1))
);

CREATE INDEX idx_usuario_perfil ON usuario(perfil);

-- =========================================================
-- VW_FATURAMENTO_CATEGORIA
-- Alimenta a tela de relatório consolidado da aplicação.
-- A tela só faz SELECT nesta visão: nenhuma regra de apuração fica
-- escrita no código Java.
--
-- RN19: pedidos cancelados ficam de fora do faturamento.
-- =========================================================
CREATE OR REPLACE VIEW vw_faturamento_categoria AS
SELECT
    c.idcategoria,
    c.nome                                          AS categoria,
    COUNT(DISTINCT i.pedido_idpedido)               AS pedidos,
    SUM(i.quantidade)                               AS unidades_vendidas,
    ROUND(SUM(i.quantidade * i.preco_unitario), 2)  AS faturamento
FROM categoria   c
JOIN produto     p ON p.categoria_idcategoria = c.idcategoria
JOIN item_pedido i ON i.produto_idproduto     = p.idproduto
JOIN pedido      d ON d.idpedido              = i.pedido_idpedido
WHERE d.status <> 'CANCELADO'
GROUP BY c.idcategoria, c.nome;

-- =========================================================
-- VW_POSICAO_ESTOQUE
-- Posição de estoque com o nome do produto e da categoria, usada na
-- tela de venda para mostrar o saldo disponível.
-- =========================================================
CREATE OR REPLACE VIEW vw_posicao_estoque AS
SELECT
    p.idproduto,
    p.nome            AS produto,
    c.nome            AS categoria,
    p.preco_venda,
    p.unidade_medida,
    e.idestoque,
    e.quantidade_atual,
    e.data_atualizacao
FROM produto   p
JOIN categoria c ON c.idcategoria       = p.categoria_idcategoria
JOIN estoque   e ON e.produto_idproduto = p.idproduto;

-- =========================================================
-- Conferência
-- =========================================================
SELECT 'usuario criado' AS objeto, COUNT(*) AS linhas FROM usuario
UNION ALL SELECT 'vw_faturamento_categoria', COUNT(*) FROM vw_faturamento_categoria
UNION ALL SELECT 'vw_posicao_estoque', COUNT(*) FROM vw_posicao_estoque;
