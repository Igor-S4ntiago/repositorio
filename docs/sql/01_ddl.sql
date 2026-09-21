-- =========================================================
-- PROJETO: Sistema de Gestão para Distribuidora de Bebidas
-- ETAPA: A6 - DDL
-- ARQUIVO: 01_ddl.sql
-- SGBD: MySQL 8+
-- =========================================================
CREATE DATABASE IF NOT EXISTS distribuidora_bebidas;
USE distribuidora_bebidas;

-- =========================================================
-- PESSOA
-- =========================================================

CREATE TABLE pessoa (
    idpessoa INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    cpf CHAR(11) NOT NULL,
    telefone VARCHAR(20),
    email VARCHAR(100),

    CONSTRAINT pk_pessoa PRIMARY KEY (idpessoa), 
    CONSTRAINT uq_pessoa_cpf UNIQUE (cpf),
    CONSTRAINT uq_pessoa_email UNIQUE (email)
);

-- =========================================================
-- CLIENTE
-- Especialização de PESSOA
-- =========================================================
CREATE TABLE cliente (
    pessoa_idpessoa INT NOT NULL,
    endereco VARCHAR(200) NOT NULL,
    data_cadastro DATETIME NOT NULL,

    CONSTRAINT pk_cliente PRIMARY KEY (pessoa_idpessoa),
    CONSTRAINT fk_cliente_pessoa
        FOREIGN KEY (pessoa_idpessoa)
        REFERENCES pessoa(idpessoa)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- =========================================================
-- FUNCIONARIO
-- Especialização de PESSOA
-- Autorrelacionamento por idsupervisor
-- =========================================================
CREATE TABLE funcionario (
    pessoa_idpessoa INT NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    data_admissao DATE NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    idsupervisor INT,

    CONSTRAINT pk_funcionario
        PRIMARY KEY (pessoa_idpessoa),

    CONSTRAINT fk_funcionario_pessoa
        FOREIGN KEY (pessoa_idpessoa)
        REFERENCES pessoa(idpessoa)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_funcionario_supervisor
        FOREIGN KEY (idsupervisor)
        REFERENCES funcionario(pessoa_idpessoa)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT ck_funcionario_ativo
        CHECK (ativo IN (0, 1))
);

-- =========================================================
-- CATEGORIA
-- =========================================================

CREATE TABLE categoria (
    idcategoria INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(50) NOT NULL,
    descricao VARCHAR(200),

    CONSTRAINT pk_categoria PRIMARY KEY (idcategoria),
    CONSTRAINT uq_categoria_nome UNIQUE (nome)
);

-- =========================================================
-- PRODUTO
-- =========================================================
CREATE TABLE produto (
    idproduto INT NOT NULL AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    preco_venda DECIMAL(10,2) NOT NULL,
    unidade_medida VARCHAR(20) NOT NULL,
    categoria_idcategoria INT NOT NULL,

    CONSTRAINT pk_produto PRIMARY KEY (idproduto),

    CONSTRAINT fk_produto_categoria
        FOREIGN KEY (categoria_idcategoria)
        REFERENCES categoria(idcategoria)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT ck_produto_preco_venda
        CHECK (preco_venda >= 0)
);

-- =========================================================
-- FORNECEDOR
-- =========================================================

CREATE TABLE fornecedor (
    idfornecedor INT NOT NULL AUTO_INCREMENT,
    razao_social VARCHAR(150) NOT NULL,
    cnpj CHAR(14) NOT NULL,
    telefone VARCHAR(20),
    email VARCHAR(100),

    CONSTRAINT pk_fornecedor PRIMARY KEY (idfornecedor),
    CONSTRAINT uq_fornecedor_cnpj UNIQUE (cnpj),
    CONSTRAINT uq_fornecedor_email UNIQUE (email)
);

-- =========================================================
-- PRODUTO_FORNECEDOR
-- Relacionamento N:N
-- =========================================================
CREATE TABLE produto_fornecedor (
    produto_idproduto INT NOT NULL,
    fornecedor_idfornecedor INT NOT NULL,
    preco_comprar DECIMAL(10,2) NOT NULL,
    prazo_fornecimento INT NOT NULL,

    CONSTRAINT pk_produto_fornecedor
        PRIMARY KEY (produto_idproduto, fornecedor_idfornecedor),

    CONSTRAINT fk_produto_fornecedor_produto
        FOREIGN KEY (produto_idproduto)
        REFERENCES produto(idproduto)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_produto_fornecedor_fornecedor
        FOREIGN KEY (fornecedor_idfornecedor)
        REFERENCES fornecedor(idfornecedor)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT ck_produto_fornecedor_preco
        CHECK (preco_comprar >= 0),

    CONSTRAINT ck_produto_fornecedor_prazo
        CHECK (prazo_fornecimento >= 0)
);

-- =========================================================
-- PEDIDO
-- =========================================================
CREATE TABLE pedido (
    idpedido INT NOT NULL AUTO_INCREMENT,
    data_pedido DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL,
    cliente_pessoa_idpessoa INT NOT NULL,

    CONSTRAINT pk_pedido PRIMARY KEY (idpedido),

    CONSTRAINT fk_pedido_cliente
        FOREIGN KEY (cliente_pessoa_idpessoa)
        REFERENCES cliente(pessoa_idpessoa)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT ck_pedido_status
        CHECK (status IN (
            'ABERTO',
            'PAGO',
            'ENVIADO',
            'CANCELADO'
        ))
);

-- =========================================================
-- ITEM_PEDIDO
-- =========================================================
CREATE TABLE item_pedido (
    pedido_idpedido INT NOT NULL,
    produto_idproduto INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,

    CONSTRAINT pk_item_pedido
        PRIMARY KEY (pedido_idpedido, produto_idproduto),

    CONSTRAINT fk_item_pedido_pedido
        FOREIGN KEY (pedido_idpedido)
        REFERENCES pedido(idpedido)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_item_pedido_produto
        FOREIGN KEY (produto_idproduto)
        REFERENCES produto(idproduto)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT ck_item_pedido_quantidade
        CHECK (quantidade > 0),

    CONSTRAINT ck_item_pedido_preco
        CHECK (preco_unitario >= 0)
);

-- =========================================================
-- ESTOQUE
-- =========================================================
CREATE TABLE estoque (
    idestoque INT NOT NULL AUTO_INCREMENT,
    produto_idproduto INT NOT NULL,
    quantidade_atual INT NOT NULL,
    data_atualizacao DATETIME NOT NULL,

    CONSTRAINT pk_estoque PRIMARY KEY (idestoque),

    CONSTRAINT uq_estoque_produto UNIQUE (produto_idproduto),

    CONSTRAINT fk_estoque_produto
        FOREIGN KEY (produto_idproduto)
        REFERENCES produto(idproduto)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT ck_estoque_quantidade
        CHECK (quantidade_atual >= 0)
);

-- =========================================================
-- MOVIMENTACAO_ESTOQUE
-- =========================================================
CREATE TABLE movimentacao_estoque (
    idmovimentacao_estoque INT NOT NULL AUTO_INCREMENT,
    tipo VARCHAR(10) NOT NULL,
    quantidade INT NOT NULL,
    data_hora DATETIME NOT NULL,
    estoque_idestoque INT NOT NULL,

    CONSTRAINT pk_movimentacao_estoque
        PRIMARY KEY (idmovimentacao_estoque),

    CONSTRAINT fk_movimentacao_estoque_estoque
        FOREIGN KEY (estoque_idestoque)
        REFERENCES estoque(idestoque)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT ck_movimentacao_tipo
        CHECK (tipo IN ('ENTRADA', 'SAIDA')),

    CONSTRAINT ck_movimentacao_quantidade
        CHECK (quantidade > 0)
);

-- =========================================================
-- PAGAMENTO
-- =========================================================
CREATE TABLE pagamento (
    idpagamento INT NOT NULL AUTO_INCREMENT,
    forma_pagamento VARCHAR(30) NOT NULL,
    status_pagamento VARCHAR(20) NOT NULL,
    data_pagamento DATETIME,
    pedido_idpedido INT NOT NULL,

    CONSTRAINT pk_pagamento PRIMARY KEY (idpagamento),

    CONSTRAINT uq_pagamento_pedido UNIQUE (pedido_idpedido),

    CONSTRAINT fk_pagamento_pedido
        FOREIGN KEY (pedido_idpedido)
        REFERENCES pedido(idpedido)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT ck_pagamento_status
        CHECK (status_pagamento IN (
            'PENDENTE',
            'APROVADO',
            'RECUSADO'
        ))
);

-- =========================================================
-- ENTREGA
-- =========================================================
CREATE TABLE entrega (
    identrega INT NOT NULL AUTO_INCREMENT,
    data_prevista DATE NOT NULL,
    data_entrega DATE,
    status_entrega VARCHAR(20) NOT NULL,
    pedido_idpedido INT NOT NULL,
    funcionario_pessoa_idpessoa INT,

    CONSTRAINT pk_entrega PRIMARY KEY (identrega),

    CONSTRAINT uq_entrega_pedido UNIQUE (pedido_idpedido),

    CONSTRAINT fk_entrega_pedido
        FOREIGN KEY (pedido_idpedido)
        REFERENCES pedido(idpedido)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_entrega_funcionario
        FOREIGN KEY (funcionario_pessoa_idpessoa)
        REFERENCES funcionario(pessoa_idpessoa)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT ck_entrega_status
        CHECK (status_entrega IN (
            'PENDENTE',
            'EM_ROTA',
            'ENTREGUE'
        ))
);

-- =========================================================
-- ÍNDICES
-- =========================================================
CREATE INDEX idx_pessoa_nome
    ON pessoa(nome);

CREATE INDEX idx_produto_nome
    ON produto(nome);

CREATE INDEX idx_pedido_data
    ON pedido(data_pedido);

CREATE INDEX idx_pedido_status
    ON pedido(status);

CREATE INDEX idx_movimentacao_data
    ON movimentacao_estoque(data_hora);

CREATE INDEX idx_fornecedor_razao_social
    ON fornecedor(razao_social);

CREATE INDEX idx_funcionario_supervisor
    ON funcionario(idsupervisor);

CREATE INDEX idx_entrega_status
    ON entrega(status_entrega);