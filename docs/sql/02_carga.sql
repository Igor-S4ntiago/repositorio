-- =========================================================
-- PROJETO: Sistema de Gestão para Distribuidora de Bebidas
-- ETAPA: A7 - CARGA DE DADOS
-- ARQUIVO: 02_carga.sql
-- SGBD: MySQL 8+
--
-- Execute depois do 01_ddl.sql.
--
-- A carga segue a ordem das dependências: primeiro os cadastros
-- básicos (pessoa, categoria, fornecedor), depois produto e estoque
-- e por último as operações (pedido, item, pagamento, entrega e
-- movimentação).
--
-- Os dados são fictícios. Nomes, CPF, CNPJ, telefones e e-mails
-- foram inventados e não correspondem a pessoas ou empresas reais.
--
-- Casos de contorno colocados de propósito na carga:
--   - pessoas sem telefone e/ou sem e-mail cadastrado;
--   - cliente sem endereço (cadastro feito pelo site);
--   - clientes sem nenhum pedido;
--   - funcionário sem supervisor (o gerente geral) e funcionários
--     desligados, com ativo = 0;
--   - categorias sem nenhum produto cadastrado;
--   - produtos sem fornecedor e produto que nunca foi vendido;
--   - produtos com estoque zerado;
--   - pedidos cancelados, que têm itens mas não baixam estoque;
--   - pagamentos PENDENTE e RECUSADO, sem data de pagamento;
--   - entregas PENDENTE e EM_ROTA, sem data de entrega, e uma
--     entrega sem funcionário responsável;
--   - preço do item diferente do preço de tabela do produto, porque
--     vale o valor praticado no dia da venda (RN08).
-- =========================================================

USE distribuidora_bebidas;

-- Limpeza inicial, na ordem inversa das dependências, para o script
-- poder ser executado mais de uma vez sem dar erro de chave.
DELETE FROM movimentacao_estoque;
DELETE FROM estoque;
DELETE FROM entrega;
DELETE FROM pagamento;
DELETE FROM item_pedido;
DELETE FROM pedido;
DELETE FROM produto_fornecedor;
DELETE FROM produto;
DELETE FROM categoria;
DELETE FROM fornecedor;
DELETE FROM funcionario;
DELETE FROM cliente;
DELETE FROM pessoa;

-- =========================================================
-- CATEGORIA
-- Algumas categorias ainda não têm produto cadastrado.
-- =========================================================
INSERT INTO categoria
    (idcategoria, nome, descricao)
VALUES
    (1, 'Cerveja Pilsen', 'Cervejas claras de baixa fermentação'),
    (2, 'Cerveja IPA', 'Cervejas com lupulagem acentuada'),
    (3, 'Cerveja Weiss', 'Cervejas de trigo'),
    (4, 'Cerveja Stout', 'Cervejas escuras encorpadas'),
    (5, 'Cerveja Sem Álcool', 'Cervejas com teor alcoólico abaixo de 0,5%'),
    (6, 'Refrigerante Cola', 'Refrigerantes à base de cola'),
    (7, 'Refrigerante Guaraná', 'Refrigerantes de guaraná'),
    (8, 'Refrigerante Laranja', 'Refrigerantes cítricos');

INSERT INTO categoria
    (idcategoria, nome, descricao)
VALUES
    (9, 'Refrigerante Limão', 'Refrigerantes de limão e lima-limão'),
    (10, 'Refrigerante Diet', 'Versões zero açúcar dos refrigerantes'),
    (11, 'Água Mineral', 'Águas minerais sem gás'),
    (12, 'Água com Gás', 'Águas minerais gaseificadas'),
    (13, 'Água Tônica', 'Águas tônicas para drinques'),
    (14, 'Água de Coco', 'Água de coco industrializada'),
    (15, 'Suco Integral', 'Sucos sem adição de açúcar ou água'),
    (16, 'Suco Néctar', 'Sucos com adição de açúcar');

INSERT INTO categoria
    (idcategoria, nome, descricao)
VALUES
    (17, 'Suco Concentrado', 'Polpas e concentrados para diluição'),
    (18, 'Energético', 'Bebidas energéticas'),
    (19, 'Isotônico', 'Repositores hidroeletrolíticos'),
    (20, 'Chá Gelado', 'Chás prontos para consumo'),
    (21, 'Vinho Tinto', 'Vinhos tintos nacionais e importados'),
    (22, 'Vinho Branco', 'Vinhos brancos nacionais e importados'),
    (23, 'Vinho Rosé', 'Vinhos rosés'),
    (24, 'Espumante', 'Espumantes e frisantes');

INSERT INTO categoria
    (idcategoria, nome, descricao)
VALUES
    (25, 'Vodka', NULL),   -- sem descrição cadastrada
    (26, 'Gin', 'Gins nacionais e importados'),
    (27, 'Whisky', 'Whiskies blended e single malt'),
    (28, 'Cachaça', 'Cachaças artesanais e industriais'),
    (29, 'Rum', NULL),   -- sem descrição cadastrada
    (30, 'Tequila', 'Tequilas e destilados de agave'),
    (31, 'Licor', 'Licores cremosos e de frutas'),
    (32, 'Aperitivo', 'Aperitivos amargos e bitters');

INSERT INTO categoria
    (idcategoria, nome, descricao)
VALUES
    (33, 'Vermute', 'Vermutes secos e doces'),
    (34, 'Saquê', 'Saquês importados'),
    (35, 'Sidra', 'Sidras de maçã'),
    (36, 'Kombucha', 'Bebidas fermentadas funcionais'),
    (37, 'Achocolatado', 'Achocolatados prontos'),
    (38, 'Café Pronto', 'Cafés prontos para consumo'),
    (39, 'Xarope para Drinque', 'Xaropes e insumos de coqueteleria'),
    (40, 'Gelo', 'Gelo em cubos e escama');

-- =========================================================
-- FORNECEDOR
-- =========================================================
INSERT INTO fornecedor
    (idfornecedor, razao_social, cnpj, telefone, email)
VALUES
    (1, 'Cervejaria Vale do Sol Ltda', '73030081670547', '(61) 3879-5346', 'comercial@cervejariavaledoso.com.br'),
    (2, 'Bebidas Aurora S.A.', '27740645765655', '(61) 3940-5873', 'comercial@bebidasaurora.com.br'),
    (3, 'Distribuidora Planalto Ltda', '73033409803528', '(61) 3391-5672', 'comercial@distribuidoraplana.com.br'),
    (4, 'Cervejaria Pedra Alta Eireli', '98906847237654', '(61) 3095-8072', 'comercial@cervejariapedraalt.com.br'),
    (5, 'Águas do Cerrado Eireli', '73962844596879', '(61) 3414-8197', 'comercial@aguasdocerrado.com.br'),
    (6, 'Sucos Bela Fruta S.A.', '65682873570681', '(61) 3210-6767', 'comercial@sucosbelafruta.com.br'),
    (7, 'Importadora Del Mar Ltda', '03236195335934', NULL, 'comercial@importadoradelmar.com.br'),   -- sem telefone
    (8, 'Bebidas Rio Verde ME', '19373345273754', '(61) 3970-4287', 'comercial@bebidasrioverde.com.br');

INSERT INTO fornecedor
    (idfornecedor, razao_social, cnpj, telefone, email)
VALUES
    (9, 'Cervejaria Casa Velha Ltda', '08413912116012', '(61) 3271-3470', 'comercial@cervejariacasavelh.com.br'),
    (10, 'Refrigerantes Tropical ME', '83279987304554', '(61) 3719-0257', 'comercial@refrigerantestropi.com.br'),
    (11, 'Destilaria São Jorge Eireli', '44379381177609', '(61) 3209-6789', 'comercial@destilariasaojorge.com.br'),
    (12, 'Vinícola Serra Azul Eireli', '60570675807780', '(61) 3646-6527', NULL),   -- sem e-mail
    (13, 'Importadora Andina ME', '68544168632952', '(61) 3413-8726', 'comercial@importadoraandina.com.br'),
    (14, 'Bebidas Fonte Clara S.A.', '86248981630041', '(61) 3348-5880', 'comercial@bebidasfonteclara.com.br'),
    (15, 'Energéticos Volt ME', '56601284985706', '(61) 3198-2817', 'comercial@energeticosvolt.com.br'),
    (16, 'Laticinios e Bebidas Boa Vista ME', '25424254180172', '(61) 3237-8956', 'comercial@laticiniosebebidas.com.br');

INSERT INTO fornecedor
    (idfornecedor, razao_social, cnpj, telefone, email)
VALUES
    (17, 'Cervejaria Ferro Velho ME', '33399900355715', '(61) 3391-0037', 'comercial@cervejariaferrovel.com.br'),
    (18, 'Distribuidora Campo Belo S.A.', '72342127614282', '(61) 3697-9308', 'comercial@distribuidoracampo.com.br'),
    (19, 'Águas Minerais Itapema Eireli', '67168156544651', NULL, NULL),   -- sem telefone e sem e-mail
    (20, 'Sucos Naturais Verdejar ME', '54376178805448', '(61) 3066-8730', 'comercial@sucosnaturaisverde.com.br'),
    (21, 'Importadora Costa Norte Eireli', '87261726967465', '(61) 3393-9654', 'comercial@importadoracostano.com.br'),
    (22, 'Destilaria Alambique Real S.A.', '03679177646186', '(61) 3250-2517', 'comercial@destilariaalambiqu.com.br'),
    (23, 'Vinícola Terra Rubra S.A.', '93367694992689', '(61) 3840-0964', 'comercial@vinicolaterrarubra.com.br'),
    (24, 'Bebidas Mananciais Ltda', '35148941322656', '(61) 3965-2303', 'comercial@bebidasmananciais.com.br');

INSERT INTO fornecedor
    (idfornecedor, razao_social, cnpj, telefone, email)
VALUES
    (25, 'Cervejaria Doze Portões ME', '08674749732176', '(61) 3118-5831', 'comercial@cervejariadozeport.com.br'),
    (26, 'Gelo Polar ME', '37114847050775', '(61) 3997-3028', 'comercial@gelopolar.com.br'),
    (27, 'Distribuidora Girassol Eireli', '85848372883066', '(61) 3051-7985', 'comercial@distribuidoragiras.com.br'),
    (28, 'Bebidas Porto Seguro Ltda', '68135550064578', '(61) 3486-8330', 'comercial@bebidasportoseguro.com.br'),
    (29, 'Cervejaria Lua Cheia S.A.', '41003568588445', '(61) 3688-6983', 'comercial@cervejarialuacheia.com.br'),
    (30, 'Importadora Mediterrâneo Ltda', '96963956146684', '(61) 3933-8733', 'comercial@importadoramediter.com.br'),
    (31, 'Chás Orientais Kanto Eireli', '22899145417815', '(61) 3597-7233', 'comercial@chasorientaiskanto.com.br'),
    (32, 'Bebidas Nova Era Ltda', '02189586004211', '(61) 3063-5424', 'comercial@bebidasnovaera.com.br');

INSERT INTO fornecedor
    (idfornecedor, razao_social, cnpj, telefone, email)
VALUES
    (33, 'Refrigerantes Guara Eireli', '52659691761735', NULL, 'comercial@refrigerantesguara.com.br'),
    (34, 'Destilaria Vale Fundo Eireli', '61558113258249', '(61) 3342-2700', 'comercial@destilariavalefund.com.br'),
    (35, 'Vinícola Pedra Branca S.A.', '13662049857063', '(61) 3834-0518', 'comercial@vinicolapedrabranc.com.br'),
    (36, 'Bebidas Horizonte Ltda', '00809613461670', '(61) 3033-7233', 'comercial@bebidashorizonte.com.br'),
    (37, 'Cervejaria Tres Rios S.A.', '27441949899629', '(61) 3074-2702', 'comercial@cervejariatresrios.com.br'),
    (38, 'Importadora Nórdica ME', '30396493876376', '(61) 3295-8147', 'comercial@importadoranordica.com.br'),
    (39, 'Sucos Cidade Alta S.A.', '37690794321453', '(61) 3323-6219', 'comercial@sucoscidadealta.com.br'),
    (40, 'Bebidas São Bento Ltda', '79133723856878', '(61) 3560-5393', 'comercial@bebidassaobento.com.br');

-- =========================================================
-- PESSOA
-- Os ids de 1 a 42 viram funcionários e os de 43 a 105 viram
-- clientes nas tabelas da especialização.
-- =========================================================
INSERT INTO pessoa
    (idpessoa, nome, cpf, telefone, email)
VALUES
    (1, 'Isabela Ibrahim Almeida', '02417382313', '(61) 92246-5039', 'isabela.ibrahim1@exemplo.com.br'),
    (2, 'Eduarda Gomes Oliveira', '88908381360', '(61) 96429-5166', 'eduarda.gomes2@exemplo.com.br'),
    (3, 'Elaine Silveira Justino', '58551392075', '(61) 93347-4204', 'elaine.silveira3@exemplo.com.br'),
    (4, 'Lucas Vieira Henriques', '29258134506', '(61) 91348-2255', 'lucas.vieira4@exemplo.com.br'),
    (5, 'Paulo Peixoto Ferreira', '86789358408', '(61) 98210-4842', 'paulo.peixoto5@exemplo.com.br'),
    (6, 'Renata Esteves Cardoso', '14032689240', '(61) 97524-9388', 'renata.esteves6@exemplo.com.br'),
    (7, 'Fábio Rocha Cardoso', '38128009048', '(61) 91821-2807', 'fabio.rocha7@exemplo.com.br'),
    (8, 'Gabriela Cardoso Moraes', '46529422721', '(61) 90926-9051', 'gabriela.cardoso8@exemplo.com.br'),
    (9, 'Bruno Oliveira Esteves', '01231573042', '(61) 99662-4744', 'bruno.oliveira9@exemplo.com.br'),
    (10, 'Ana Justino Uchôa', '61287188625', '(61) 91276-3904', 'ana.justino10@exemplo.com.br');

INSERT INTO pessoa
    (idpessoa, nome, cpf, telefone, email)
VALUES
    (11, 'Eduarda Sampaio Peixoto', '62658652911', '(61) 98921-2498', 'eduarda.sampaio11@exemplo.com.br'),
    (12, 'Leandro Ramos Ferreira', '39126023549', '(61) 91170-2867', 'leandro.ramos12@exemplo.com.br'),
    (13, 'Elaine Esteves Zanetti', '50315687651', '(61) 98046-0467', 'elaine.esteves13@exemplo.com.br'),
    (14, 'Tatiane Cardoso Moraes', '72893923144', '(61) 90434-8193', 'tatiane.cardoso14@exemplo.com.br'),
    (15, 'Rafael Nogueira Vieira', '40769551201', '(61) 90982-7878', 'rafael.nogueira15@exemplo.com.br'),
    (16, 'Henrique Zanetti Ferreira', '74201148351', '(61) 98377-2151', 'henrique.zanetti16@exemplo.com.br'),
    (17, 'Denise Esteves Sampaio', '97813451423', '(61) 98022-3513', 'denise.esteves17@exemplo.com.br'),
    (18, 'Alice Peixoto Silveira', '48983289217', NULL, 'alice.peixoto18@exemplo.com.br'),   -- funcionário sem telefone
    (19, 'Emerson Ferreira Silveira', '47919735205', '(61) 90477-9242', 'emerson.ferreira19@exemplo.com.br'),
    (20, 'Leandro Rocha Zanetti', '50014647268', '(61) 96287-4241', 'leandro.rocha20@exemplo.com.br');

INSERT INTO pessoa
    (idpessoa, nome, cpf, telefone, email)
VALUES
    (21, 'Samuel Tavares Cardoso', '01552637972', '(61) 99737-5392', 'samuel.tavares21@exemplo.com.br'),
    (22, 'Daniel Cardoso Oliveira', '56166581592', '(61) 92305-8953', 'daniel.cardoso22@exemplo.com.br'),
    (23, 'Eduarda Almeida Ramos', '20090332103', '(61) 91768-4844', 'eduarda.almeida23@exemplo.com.br'),
    (24, 'Thiago Nogueira Vieira', '83088727456', '(61) 99643-8413', 'thiago.nogueira24@exemplo.com.br'),
    (25, 'Mariana Nogueira Almeida', '95239345393', '(61) 97695-3369', 'mariana.nogueira25@exemplo.com.br'),
    (26, 'Felipe Tavares Gomes', '76694007045', '(61) 91879-4656', 'felipe.tavares26@exemplo.com.br'),
    (27, 'Alice Justino Silveira', '76875847525', '(61) 99670-4828', NULL),   -- funcionário sem e-mail
    (28, 'Carla Almeida Ferreira', '81009117582', '(61) 99208-9439', 'carla.almeida28@exemplo.com.br'),
    (29, 'Rafael Tavares Teixeira', '06782648581', '(61) 93946-8287', 'rafael.tavares29@exemplo.com.br'),
    (30, 'Hugo Gomes Ramos', '55779245346', '(61) 92365-0217', 'hugo.gomes30@exemplo.com.br');

INSERT INTO pessoa
    (idpessoa, nome, cpf, telefone, email)
VALUES
    (31, 'Alice Nogueira Queiroz', '91917167731', NULL, 'alice.nogueira31@exemplo.com.br'),
    (32, 'Lucas Dias Lima', '73422434639', '(61) 98970-3478', 'lucas.dias32@exemplo.com.br'),
    (33, 'Elaine Ramos Xavier', '45141959011', '(61) 94277-6554', 'elaine.ramos33@exemplo.com.br'),
    (34, 'Felipe Nogueira Cardoso', '40057960507', '(61) 95029-7486', 'felipe.nogueira34@exemplo.com.br'),
    (35, 'Caio Teixeira Ramos', '71167459447', '(61) 96913-3383', 'caio.teixeira35@exemplo.com.br'),
    (36, 'Samuel Dias Uchôa', '50802859425', '(61) 92892-7280', 'samuel.dias36@exemplo.com.br'),
    (37, 'Otávio Uchôa Ferreira', '75815922279', '(61) 90375-5788', 'otavio.uchoa37@exemplo.com.br'),
    (38, 'Hugo Justino Ferreira', '48213375334', '(61) 96315-4626', 'hugo.justino38@exemplo.com.br'),
    (39, 'Vinícius Nogueira Henriques', '91505802380', '(61) 98058-1233', 'vinicius.nogueira39@exemplo.com.br'),
    (40, 'Marcelo Ramos Ramos', '48592897146', '(61) 93233-4307', 'marcelo.ramos40@exemplo.com.br');

INSERT INTO pessoa
    (idpessoa, nome, cpf, telefone, email)
VALUES
    (41, 'Giovana Esteves Gomes', '88786450554', '(61) 93742-7123', 'giovana.esteves41@exemplo.com.br'),
    (42, 'Otávio Moraes Lima', '42058917532', '(61) 92705-5621', 'otavio.moraes42@exemplo.com.br'),
    (43, 'Rafael Tavares Rocha', '11610918287', '(61) 98822-8911', 'rafael.tavares43@exemplo.com.br'),
    (44, 'Felipe Macedo Uchôa', '06670346958', '(61) 92620-0975', 'felipe.macedo44@exemplo.com.br'),
    (45, 'Elaine Ferreira Justino', '74806779823', '(61) 97806-8632', 'elaine.ferreira45@exemplo.com.br'),
    (46, 'Nelson Ramos Henriques', '23398159932', '(61) 99929-0141', 'nelson.ramos46@exemplo.com.br'),
    (47, 'Karina Tavares Barbosa', '11028541137', '(61) 95678-5667', 'karina.tavares47@exemplo.com.br'),
    (48, 'Fábio Tavares Gomes', '38826425881', '(61) 94954-8372', 'fabio.tavares48@exemplo.com.br'),
    (49, 'Henrique Peixoto Nogueira', '16114629246', '(61) 91838-3393', 'henrique.peixoto49@exemplo.com.br'),
    (50, 'Karina Zanetti Oliveira', '21146982730', '(61) 90339-7573', 'karina.zanetti50@exemplo.com.br');

INSERT INTO pessoa
    (idpessoa, nome, cpf, telefone, email)
VALUES
    (51, 'Vinícius Teixeira Moraes', '22950723805', NULL, 'vinicius.teixeira51@exemplo.com.br'),   -- cliente sem telefone
    (52, 'Samuel Barbosa Silveira', '41610014783', '(61) 98563-0660', 'samuel.barbosa52@exemplo.com.br'),
    (53, 'Sabrina Vieira Gomes', '62997553567', '(61) 93617-0313', 'sabrina.vieira53@exemplo.com.br'),
    (54, 'Thiago Dias Vieira', '75766500912', '(61) 99475-3009', 'thiago.dias54@exemplo.com.br'),
    (55, 'Elaine Cardoso Nogueira', '67419634919', '(61) 90925-1041', 'elaine.cardoso55@exemplo.com.br'),
    (56, 'Marcelo Rocha Gomes', '45089309322', '(61) 96990-0825', 'marcelo.rocha56@exemplo.com.br'),
    (57, 'Paulo Xavier Gomes', '57052436650', '(61) 95294-7240', NULL),
    (58, 'Fábio Ferreira Ramos', '42707917332', '(61) 96129-5937', 'fabio.ferreira58@exemplo.com.br'),
    (59, 'Gabriela Barbosa Vieira', '25693146746', '(61) 92393-1568', 'gabriela.barbosa59@exemplo.com.br'),
    (60, 'Vanessa Silveira Pereira', '62613216752', '(61) 93553-6626', 'vanessa.silveira60@exemplo.com.br');

INSERT INTO pessoa
    (idpessoa, nome, cpf, telefone, email)
VALUES
    (61, 'Marcelo Queiroz Rocha', '44841592657', '(61) 98839-2997', 'marcelo.queiroz61@exemplo.com.br'),
    (62, 'Lucas Vieira Oliveira', '71650553871', '(61) 93982-4880', 'lucas.vieira62@exemplo.com.br'),
    (63, 'Vanessa Ibrahim Uchôa', '64063305276', '(61) 98346-9561', 'vanessa.ibrahim63@exemplo.com.br'),
    (64, 'Natália Teixeira Sampaio', '47987144235', '(61) 90098-7290', 'natalia.teixeira64@exemplo.com.br'),
    (65, 'Otávio Pereira Xavier', '60475343487', '(61) 91244-3299', 'otavio.pereira65@exemplo.com.br'),
    (66, 'Eduarda Uchôa Macedo', '49578781099', '(61) 91336-6143', 'eduarda.uchoa66@exemplo.com.br'),
    (67, 'Renata Uchôa Xavier', '33988563120', '(61) 90997-7657', 'renata.uchoa67@exemplo.com.br'),
    (68, 'Patrícia Lima Moraes', '90923528812', NULL, 'patricia.lima68@exemplo.com.br'),
    (69, 'Karina Esteves Henriques', '59110419636', '(61) 95924-8833', 'karina.esteves69@exemplo.com.br'),
    (70, 'Tatiane Pereira Vieira', '73353964982', '(61) 98998-9382', 'tatiane.pereira70@exemplo.com.br');

INSERT INTO pessoa
    (idpessoa, nome, cpf, telefone, email)
VALUES
    (71, 'Tatiane Justino Zanetti', '32257475614', '(61) 95493-5454', 'tatiane.justino71@exemplo.com.br'),
    (72, 'Renata Zanetti Gomes', '13313852938', '(61) 98043-5674', 'renata.zanetti72@exemplo.com.br'),
    (73, 'João Ramos Moraes', '89996106491', '(61) 98727-7312', 'joao.ramos73@exemplo.com.br'),
    (74, 'Emerson Uchôa Dias', '56404024505', '(61) 96205-6340', 'emerson.uchoa74@exemplo.com.br'),
    (75, 'Elaine Teixeira Ferreira', '49336160438', '(61) 92316-6769', 'elaine.teixeira75@exemplo.com.br'),
    (76, 'Carla Ibrahim Rocha', '85724492332', '(61) 92929-0823', 'carla.ibrahim76@exemplo.com.br'),
    (77, 'Giovana Macedo Nogueira', '95183463574', '(61) 91291-2280', NULL),
    (78, 'Natália Gomes Justino', '68411141917', '(61) 97835-1529', 'natalia.gomes78@exemplo.com.br'),
    (79, 'Lucas Silveira Macedo', '57095064433', '(61) 96391-8989', 'lucas.silveira79@exemplo.com.br'),
    (80, 'Samuel Pereira Cardoso', '98964721624', '(61) 96709-4423', 'samuel.pereira80@exemplo.com.br');

INSERT INTO pessoa
    (idpessoa, nome, cpf, telefone, email)
VALUES
    (81, 'Mariana Almeida Silveira', '08499516556', '(61) 93363-1395', 'mariana.almeida81@exemplo.com.br'),
    (82, 'Sabrina Nogueira Ferreira', '68599434239', '(61) 92554-4100', 'sabrina.nogueira82@exemplo.com.br'),
    (83, 'Thiago Esteves Peixoto', '48369181336', '(61) 98038-3140', 'thiago.esteves83@exemplo.com.br'),
    (84, 'Renata Barbosa Silveira', '88109130003', '(61) 99131-3501', 'renata.barbosa84@exemplo.com.br'),
    (85, 'Felipe Uchôa Queiroz', '84274612120', '(61) 90339-2986', 'felipe.uchoa85@exemplo.com.br'),
    (86, 'Carla Lima Gomes', '36131440535', '(61) 90720-1087', 'carla.lima86@exemplo.com.br'),
    (87, 'Ana Silveira Xavier', '91039047031', '(61) 99691-3452', 'ana.silveira87@exemplo.com.br'),
    (88, 'Camila Oliveira Queiroz', '42939687797', '(61) 92190-3813', NULL),
    (89, 'Elaine Oliveira Vieira', '29030914346', '(61) 98676-5573', 'elaine.oliveira89@exemplo.com.br'),
    (90, 'Natália Almeida Queiroz', '82276087100', NULL, 'natalia.almeida90@exemplo.com.br');

INSERT INTO pessoa
    (idpessoa, nome, cpf, telefone, email)
VALUES
    (91, 'João Esteves Uchôa', '25422156215', '(61) 96908-6117', 'joao.esteves91@exemplo.com.br'),
    (92, 'Hugo Tavares Pereira', '85786371145', '(61) 96417-5730', 'hugo.tavares92@exemplo.com.br'),
    (93, 'Sabrina Moraes Henriques', '69333270723', '(61) 95785-1522', 'sabrina.moraes93@exemplo.com.br'),
    (94, 'Hugo Henriques Ibrahim', '14277518323', '(61) 97871-6200', 'hugo.henriques94@exemplo.com.br'),
    (95, 'Carla Almeida Pereira', '55020116623', '(61) 91546-6704', 'carla.almeida95@exemplo.com.br'),
    (96, 'Giovana Macedo Dias', '46701828321', '(61) 98182-1485', 'giovana.macedo96@exemplo.com.br'),
    (97, 'Caio Sampaio Sampaio', '64935982297', '(61) 93034-9630', 'caio.sampaio97@exemplo.com.br'),
    (98, 'Camila Uchôa Queiroz', '41123939152', '(61) 95916-8527', 'camila.uchoa98@exemplo.com.br'),
    (99, 'Paulo Tavares Nogueira', '63415188017', '(61) 96063-7680', NULL),
    (100, 'Rafael Gomes Silveira', '75989012891', '(61) 98993-8933', 'rafael.gomes100@exemplo.com.br');

INSERT INTO pessoa
    (idpessoa, nome, cpf, telefone, email)
VALUES
    (101, 'Caio Ramos Gomes', '53019368985', '(61) 99561-9205', 'caio.ramos101@exemplo.com.br'),
    (102, 'Denise Lima Xavier', '71339207553', '(61) 93085-1083', 'denise.lima102@exemplo.com.br'),
    (103, 'Elaine Peixoto Moraes', '81091090503', '(61) 91860-5872', 'elaine.peixoto103@exemplo.com.br'),
    (104, 'Wagner Queiroz Ibrahim', '85959618205', '(61) 95103-1553', 'wagner.queiroz104@exemplo.com.br'),
    (105, 'Hugo Queiroz Pereira', '74642464278', '(61) 90103-8233', 'hugo.queiroz105@exemplo.com.br');

-- =========================================================
-- FUNCIONARIO
-- Hierarquia: o gerente geral não tem supervisor; abaixo dele vêm
-- três supervisores, sete líderes e a equipe operacional.
-- =========================================================
INSERT INTO funcionario
    (pessoa_idpessoa, cargo, data_admissao, ativo, idsupervisor)
VALUES
    (1, 'Gerente Geral', '2016-03-07', 1, NULL),   -- topo da hierarquia, sem supervisor
    (2, 'Supervisor de Operações', '2017-05-25', 1, 1),
    (3, 'Supervisor de Operações', '2018-07-16', 1, 1),
    (4, 'Supervisor de Operações', '2019-10-26', 1, 1),
    (5, 'Líder de Equipe', '2021-10-16', 1, 2),
    (6, 'Líder de Equipe', '2018-01-27', 1, 4),
    (7, 'Líder de Equipe', '2021-07-21', 1, 4),
    (8, 'Líder de Equipe', '2019-10-13', 1, 3),
    (9, 'Líder de Equipe', '2018-01-04', 1, 4),
    (10, 'Líder de Equipe', '2018-02-09', 1, 4);

INSERT INTO funcionario
    (pessoa_idpessoa, cargo, data_admissao, ativo, idsupervisor)
VALUES
    (11, 'Líder de Equipe', '2019-10-19', 1, 3),
    (12, 'Motorista', '2020-06-28', 1, 7),
    (13, 'Vendedor', '2019-04-21', 1, 10),
    (14, 'Estoquista', '2026-09-28', 1, 9),
    (15, 'Vendedor', '2019-01-10', 1, 8),
    (16, 'Conferente', '2025-08-13', 1, 5),
    (17, 'Vendedor', '2023-02-26', 1, 10),
    (18, 'Vendedor', '2022-04-22', 1, 11),
    (19, 'Motorista', '2022-09-15', 0, 7),
    (20, 'Vendedor', '2020-07-12', 1, 6);

INSERT INTO funcionario
    (pessoa_idpessoa, cargo, data_admissao, ativo, idsupervisor)
VALUES
    (21, 'Vendedor', '2026-05-06', 1, 5),
    (22, 'Vendedor', '2022-04-21', 1, 9),
    (23, 'Conferente', '2019-11-24', 1, 11),
    (24, 'Motorista', '2023-11-15', 1, 5),
    (25, 'Motorista', '2026-07-21', 1, 9),
    (26, 'Conferente', '2026-04-04', 1, 6),
    (27, 'Estoquista', '2026-05-01', 1, 8),
    (28, 'Conferente', '2024-02-04', 0, 8),
    (29, 'Vendedor', '2021-03-27', 1, 8),
    (30, 'Estoquista', '2025-03-15', 1, 5);

INSERT INTO funcionario
    (pessoa_idpessoa, cargo, data_admissao, ativo, idsupervisor)
VALUES
    (31, 'Motorista', '2024-08-03', 1, 7),
    (32, 'Vendedor', '2022-02-05', 1, 9),
    (33, 'Motorista', '2023-07-07', 1, 7),
    (34, 'Estoquista', '2023-09-03', 1, 11),
    (35, 'Conferente', '2026-01-26', 1, 8),
    (36, 'Vendedor', '2025-01-14', 1, 7),
    (37, 'Auxiliar Administrativo', '2023-10-15', 0, 11),
    (38, 'Vendedor', '2023-12-24', 1, 6),
    (39, 'Vendedor', '2026-05-28', 1, 6),
    (40, 'Auxiliar Administrativo', '2026-09-19', 1, 10);

INSERT INTO funcionario
    (pessoa_idpessoa, cargo, data_admissao, ativo, idsupervisor)
VALUES
    (41, 'Motorista', '2022-07-28', 0, 5),
    (42, 'Motorista', '2026-09-07', 1, 8);

-- =========================================================
-- CLIENTE
-- =========================================================
INSERT INTO cliente
    (pessoa_idpessoa, endereco, data_cadastro)
VALUES
    (43, 'Quadra 104 Norte, Conjunto 3, Brasilia - DF', '2023-10-28 12:15:00'),
    (44, 'SCS Quadra 8, Bloco B-50, Valparaíso de Goias - GO', '2026-03-20 13:45:00'),
    (45, 'Rua das Palmeiras, 380, Brasilia - DF', '2024-05-20 12:50:00'),
    (46, 'Av. Hélio Prates, 1500, Luziânia - GO', '2025-08-20 18:15:00'),
    (47, 'Setor de Indústrias, Quadra 4, Lote 11, Ceilândia - DF', '2023-03-15 17:30:00'),
    (48, 'QI 23, Bloco C, Loja 4, Ceilândia - DF', '2023-04-18 15:50:00'),
    (49, 'SCS Quadra 8, Bloco B-50, Taguatinga - DF', '2023-06-08 08:20:00'),
    (50, 'Av. Hélio Prates, 1500, Valparaíso de Goias - GO', '2024-07-23 13:40:00'),
    (51, 'Setor de Indústrias, Quadra 4, Lote 11, Luziânia - GO', '2026-01-10 14:30:00'),
    (52, 'Av. Comercial Norte, 145, Gama - DF', '2024-04-23 15:20:00');

INSERT INTO cliente
    (pessoa_idpessoa, endereco, data_cadastro)
VALUES
    (53, 'Av. das Araucárias, 4400, Taguatinga - DF', '2024-03-13 16:45:00'),
    (54, 'SCS Quadra 8, Bloco B-50, Águas Claras - DF', '2023-02-01 14:45:00'),
    (55, 'QNM 34, Conjunto B, Lote 12, Ceilândia - DF', '2023-10-24 14:30:00'),
    (56, 'Av. Hélio Prates, 1500, Águas Claras - DF', '2025-03-27 17:45:00'),
    (57, 'Quadra 302 Sul, Bloco A, Águas Claras - DF', '2024-02-10 09:45:00'),
    (58, 'QNM 34, Conjunto B, Lote 12, Ceilândia - DF', '2025-12-06 17:40:00'),
    (59, 'Setor de Indústrias, Quadra 4, Lote 11, Águas Claras - DF', '2025-02-16 13:45:00'),
    (60, 'Av. Hélio Prates, 1500, Valparaíso de Goias - GO', '2024-11-19 10:40:00'),
    (61, 'QI 23, Bloco C, Loja 4, Valparaíso de Goias - GO', '2025-01-17 14:50:00'),
    (62, 'QS 5, Rua 210, Lote 40, Valparaíso de Goias - GO', '2025-01-11 08:15:00');

INSERT INTO cliente
    (pessoa_idpessoa, endereco, data_cadastro)
VALUES
    (63, 'QI 23, Bloco C, Loja 4, Luziânia - GO', '2023-11-07 14:10:00'),
    (64, 'Av. das Araucárias, 4400, Sobradinho - DF', '2024-02-22 10:30:00'),
    (65, 'Quadra 302 Sul, Bloco A, Valparaíso de Goias - GO', '2023-02-05 11:10:00'),
    (66, 'SIA Trecho 3, Lote 625, Gama - DF', '2023-07-04 09:15:00'),
    (67, 'QNM 34, Conjunto B, Lote 12, Ceilândia - DF', '2025-03-26 13:50:00'),
    (68, 'Setor de Indústrias, Quadra 4, Lote 11, Taguatinga - DF', '2026-03-08 14:40:00'),
    (69, 'Rua das Palmeiras, 380, Taguatinga - DF', '2026-08-19 10:15:00'),
    (70, 'Av. das Araucárias, 4400, Ceilândia - DF', '2023-05-03 09:40:00'),
    (71, 'Av. Central, 2210, Luziânia - GO', '2023-02-26 11:45:00'),
    (72, 'Rua do Comércio, 77, Ceilândia - DF', '2025-06-15 10:15:00');

INSERT INTO cliente
    (pessoa_idpessoa, endereco, data_cadastro)
VALUES
    (73, 'Setor de Indústrias, Quadra 4, Lote 11, Ceilândia - DF', '2024-08-13 16:50:00'),
    (74, 'Quadra 302 Sul, Bloco A, Ceilândia - DF', '2023-07-15 12:40:00'),
    (75, 'Av. das Araucárias, 4400, Águas Claras - DF', '2023-07-17 09:50:00'),
    (76, 'SCS Quadra 8, Bloco B-50, Águas Claras - DF', '2024-11-05 14:20:00'),
    (77, 'SIA Trecho 3, Lote 625, Gama - DF', '2023-01-22 12:20:00'),
    (78, 'Av. Hélio Prates, 1500, Taguatinga - DF', '2025-03-14 08:40:00'),
    (79, 'Av. das Araucárias, 4400, Ceilândia - DF', '2023-01-25 13:45:00'),
    (80, 'QI 23, Bloco C, Loja 4, Águas Claras - DF', '2026-06-03 12:30:00'),
    (81, 'Rua das Palmeiras, 380, Brasilia - DF', '2026-08-05 10:30:00'),
    (82, 'Setor de Indústrias, Quadra 4, Lote 11, Ceilândia - DF', '2024-08-19 16:00:00');

INSERT INTO cliente
    (pessoa_idpessoa, endereco, data_cadastro)
VALUES
    (83, 'Setor de Indústrias, Quadra 4, Lote 11, Brasilia - DF', '2024-06-28 08:00:00'),
    (84, 'Quadra 302 Sul, Bloco A, Valparaíso de Goias - GO', '2024-05-05 10:30:00'),
    (85, 'QNM 34, Conjunto B, Lote 12, Águas Claras - DF', '2023-01-08 17:20:00'),
    (86, 'Quadra 104 Norte, Conjunto 3, Valparaíso de Goias - GO', '2025-03-16 10:50:00'),
    (87, 'QI 23, Bloco C, Loja 4, Gama - DF', '2026-08-23 10:30:00'),
    (88, 'QS 5, Rua 210, Lote 40, Sobradinho - DF', '2026-04-10 08:20:00'),
    (89, 'Quadra 302 Sul, Bloco A, Águas Claras - DF', '2026-02-10 13:40:00'),
    (90, 'QS 5, Rua 210, Lote 40, Sobradinho - DF', '2024-08-01 09:15:00'),
    (91, 'Quadra 104 Norte, Conjunto 3, Taguatinga - DF', '2026-05-23 14:10:00'),
    (92, 'QNM 34, Conjunto B, Lote 12, Águas Claras - DF', '2023-08-21 14:00:00');

INSERT INTO cliente
    (pessoa_idpessoa, endereco, data_cadastro)
VALUES
    (93, 'SHIS QI 11, Bloco F, Ceilândia - DF', '2023-04-15 15:10:00'),
    (94, 'QI 23, Bloco C, Loja 4, Luziânia - GO', '2026-03-26 12:30:00'),
    (95, 'QI 23, Bloco C, Loja 4, Luziânia - GO', '2023-03-11 18:00:00'),
    (96, 'Rua das Palmeiras, 380, Gama - DF', '2023-08-01 14:15:00'),
    (97, 'QI 23, Bloco C, Loja 4, Brasilia - DF', '2026-08-26 10:30:00'),
    (98, 'Rua das Palmeiras, 380, Ceilândia - DF', '2025-01-19 10:50:00'),
    (99, 'SIA Trecho 3, Lote 625, Águas Claras - DF', '2024-11-03 15:10:00'),
    (100, 'Quadra 302 Sul, Bloco A, Gama - DF', '2024-03-22 14:30:00'),
    (101, 'Av. Central, 2210, Brasilia - DF', '2025-08-03 14:20:00'),
    (102, 'Av. Hélio Prates, 1500, Taguatinga - DF', '2023-05-10 11:10:00');

INSERT INTO cliente
    (pessoa_idpessoa, endereco, data_cadastro)
VALUES
    (103, 'SIA Trecho 3, Lote 625, Luziânia - GO', '2024-07-28 12:40:00'),
    (104, NULL, '2026-04-06 15:20:00'),   -- cadastro pelo site, endereço em branco
    (105, 'Av. Central, 2210, Águas Claras - DF', '2024-12-11 09:50:00');

-- =========================================================
-- PRODUTO
-- =========================================================
INSERT INTO produto
    (idproduto, nome, preco_venda, unidade_medida, categoria_idcategoria)
VALUES
    (1, 'Cerveja Pilsen Lata 350ml Cx 12', 47.90, 'CX', 1),
    (2, 'Cerveja Pilsen Long Neck 355ml Cx 24', 119.90, 'CX', 1),
    (3, 'Cerveja Pilsen Garrafa 600ml', 9.80, 'UN', 1),
    (4, 'Cerveja Pilsen Barril 5L', 89.90, 'UN', 1),
    (5, 'Cerveja IPA Lata 473ml', 14.50, 'UN', 2),
    (6, 'Cerveja IPA Garrafa 355ml Cx 6', 78.00, 'CX', 2),
    (7, 'Cerveja Session IPA Lata 350ml', 11.90, 'UN', 2),
    (8, 'Cerveja Weiss Garrafa 500ml', 16.40, 'UN', 3),
    (9, 'Cerveja Weiss Lata 473ml Cx 12', 167.00, 'CX', 3),
    (10, 'Cerveja Stout Garrafa 500ml', 18.90, 'UN', 4);

INSERT INTO produto
    (idproduto, nome, preco_venda, unidade_medida, categoria_idcategoria)
VALUES
    (11, 'Cerveja Stout Lata 350ml Cx 6', 89.00, 'CX', 4),
    (12, 'Cerveja Sem Álcool Lata 350ml Cx 12', 52.00, 'CX', 5),
    (13, 'Refrigerante Cola 2L', 9.49, 'UN', 6),
    (14, 'Refrigerante Cola Lata 350ml Cx 12', 38.90, 'CX', 6),
    (15, 'Refrigerante Cola 600ml Fd 12', 54.00, 'FD', 6),
    (16, 'Refrigerante Guaraná 2L', 8.90, 'UN', 7),
    (17, 'Refrigerante Guaraná Lata 350ml Cx 12', 36.50, 'CX', 7),
    (18, 'Refrigerante Laranja 2L', 8.20, 'UN', 8),
    (19, 'Refrigerante Limão 2L', 8.20, 'UN', 9),
    (20, 'Refrigerante Cola Zero 2L', 9.49, 'UN', 10);

INSERT INTO produto
    (idproduto, nome, preco_venda, unidade_medida, categoria_idcategoria)
VALUES
    (21, 'Refrigerante Guaraná Zero Lata 350ml Cx 12', 36.50, 'CX', 10),
    (22, 'Água Mineral 500ml Fd 12', 17.90, 'FD', 11),
    (23, 'Água Mineral 1,5L Fd 6', 21.50, 'FD', 11),
    (24, 'Água Mineral Galao 20L', 22.00, 'UN', 11),
    (25, 'Água com Gás 500ml Fd 12', 21.90, 'FD', 12),
    (26, 'Água Tônica Lata 350ml Cx 6', 27.90, 'CX', 13),
    (27, 'Água de Coco 1L Cx 12', 96.00, 'CX', 14),
    (28, 'Suco Integral Uva 1,5L', 24.90, 'UN', 15),
    (29, 'Suco Integral Laranja 900ml', 16.90, 'UN', 15),
    (30, 'Suco Néctar Pêssego 1L Cx 12', 78.00, 'CX', 16);

INSERT INTO produto
    (idproduto, nome, preco_venda, unidade_medida, categoria_idcategoria)
VALUES
    (31, 'Suco Néctar Manga 200ml Cx 27', 62.00, 'CX', 16),
    (32, 'Suco Concentrado Maracujá 500ml', 19.90, 'UN', 17),
    (33, 'Energético Lata 250ml Cx 24', 168.00, 'CX', 18),
    (34, 'Energético Lata 473ml', 12.90, 'UN', 18),
    (35, 'Isotônico 500ml Cx 12', 71.90, 'CX', 19),
    (36, 'Chá Gelado Limão 1,5L', 11.50, 'UN', 20),
    (37, 'Chá Gelado Pêssego Lata 340ml Cx 12', 54.00, 'CX', 20),
    (38, 'Vinho Tinto Cabernet 750ml', 58.90, 'GF', 21),
    (39, 'Vinho Tinto Malbec 750ml', 74.90, 'GF', 21),
    (40, 'Vinho Tinto Merlot 750ml Cx 6', 312.00, 'CX', 21);

INSERT INTO produto
    (idproduto, nome, preco_venda, unidade_medida, categoria_idcategoria)
VALUES
    (41, 'Vinho Branco Chardonnay 750ml', 62.00, 'GF', 22),
    (42, 'Vinho Branco Sauvignon 750ml', 59.90, 'GF', 22),
    (43, 'Vinho Rosé 750ml', 54.00, 'GF', 23),
    (44, 'Espumante Brut 750ml', 68.00, 'GF', 24),
    (45, 'Espumante Moscatel 750ml', 49.90, 'GF', 24),
    (46, 'Vodka 1L', 42.90, 'GF', 25),
    (47, 'Vodka Importada 750ml', 119.00, 'GF', 25),
    (48, 'Gin Nacional 750ml', 79.90, 'GF', 26),
    (49, 'Gin Importado 750ml', 189.00, 'GF', 26),
    (50, 'Whisky 8 Anos 1L', 129.90, 'GF', 27);

INSERT INTO produto
    (idproduto, nome, preco_venda, unidade_medida, categoria_idcategoria)
VALUES
    (51, 'Whisky 12 Anos 750ml', 219.00, 'GF', 27),
    (52, 'Cachaça Ouro 700ml', 38.90, 'GF', 28),
    (53, 'Cachaça Prata 965ml', 24.90, 'GF', 28),
    (54, 'Rum Dourado 750ml', 64.90, 'GF', 29),
    (55, 'Tequila Prata 750ml', 148.00, 'GF', 30),
    (56, 'Licor de Cacau 720ml', 54.90, 'GF', 31),
    (57, 'Aperitivo Amargo 900ml', 47.00, 'GF', 32),
    (58, 'Vermute Seco 1L', 39.90, 'GF', 33),   -- produto que nunca foi vendido
    (59, 'Xarope de Groselha 900ml', 18.90, 'UN', 39),
    (60, 'Gelo em Cubos 5kg', 12.00, 'PC', 40);

-- =========================================================
-- PRODUTO_FORNECEDOR
-- Mesmo produto comprado de fornecedores diferentes, cada um com
-- seu preço e seu prazo. Os produtos 59 e 60 ainda não têm
-- fornecedor cadastrado.
-- =========================================================
INSERT INTO produto_fornecedor
    (produto_idproduto, fornecedor_idfornecedor, preco_comprar, prazo_fornecimento)
VALUES
    (1, 25, 36.30, 7),
    (2, 10, 88.67, 1),
    (2, 33, 83.08, 3),
    (3, 26, 7.28, 2),
    (3, 12, 6.32, 15),
    (4, 11, 59.10, 1),
    (4, 28, 52.81, 14),
    (5, 17, 8.90, 15),
    (6, 4, 56.37, 7),
    (6, 15, 49.21, 7);

INSERT INTO produto_fornecedor
    (produto_idproduto, fornecedor_idfornecedor, preco_comprar, prazo_fornecimento)
VALUES
    (7, 9, 7.85, 7),
    (8, 33, 11.96, 15),
    (8, 8, 9.88, 1),
    (9, 1, 112.97, 2),
    (9, 32, 125.02, 7),
    (10, 40, 11.70, 3),
    (11, 34, 62.41, 2),
    (12, 35, 35.49, 3),
    (12, 40, 37.15, 30),
    (13, 29, 6.83, 1);

INSERT INTO produto_fornecedor
    (produto_idproduto, fornecedor_idfornecedor, preco_comprar, prazo_fornecimento)
VALUES
    (13, 34, 6.66, 7),
    (14, 8, 23.25, 1),
    (14, 37, 25.35, 14),
    (15, 40, 40.37, 21),
    (16, 28, 6.48, 15),
    (17, 34, 26.35, 2),
    (18, 22, 5.27, 2),
    (18, 12, 5.29, 21),
    (19, 29, 5.31, 10),
    (19, 37, 5.02, 5);

INSERT INTO produto_fornecedor
    (produto_idproduto, fornecedor_idfornecedor, preco_comprar, prazo_fornecimento)
VALUES
    (19, 38, 6.00, 10),
    (20, 2, 7.10, 10),
    (21, 22, 23.24, 14),
    (21, 17, 27.09, 7),
    (21, 27, 23.09, 7),
    (22, 30, 10.59, 7),
    (23, 6, 13.95, 21),
    (23, 2, 16.32, 5),
    (24, 2, 14.31, 10),
    (25, 17, 14.25, 5);

INSERT INTO produto_fornecedor
    (produto_idproduto, fornecedor_idfornecedor, preco_comprar, prazo_fornecimento)
VALUES
    (25, 11, 16.45, 3),
    (25, 31, 14.10, 21),
    (26, 17, 17.84, 30),
    (26, 36, 17.81, 5),
    (27, 22, 69.65, 10),
    (27, 14, 55.93, 10),
    (28, 28, 14.50, 15),
    (28, 26, 17.22, 2),
    (29, 26, 10.20, 21),
    (30, 24, 52.50, 3);

INSERT INTO produto_fornecedor
    (produto_idproduto, fornecedor_idfornecedor, preco_comprar, prazo_fornecimento)
VALUES
    (30, 18, 57.30, 10),
    (31, 2, 39.40, 14),
    (31, 7, 37.18, 2),
    (31, 26, 40.71, 2),
    (32, 3, 13.84, 3),
    (33, 39, 108.96, 15),
    (33, 13, 107.29, 2),
    (33, 29, 113.20, 7),
    (34, 5, 8.19, 30),
    (34, 9, 8.33, 7);

INSERT INTO produto_fornecedor
    (produto_idproduto, fornecedor_idfornecedor, preco_comprar, prazo_fornecimento)
VALUES
    (35, 4, 46.70, 14),
    (35, 24, 44.15, 2),
    (36, 3, 8.55, 21),
    (36, 14, 7.63, 14),
    (37, 26, 37.56, 21),
    (37, 32, 32.22, 7),
    (38, 20, 39.15, 10),
    (38, 10, 35.64, 7),
    (39, 19, 53.07, 7),
    (39, 32, 54.86, 14);

INSERT INTO produto_fornecedor
    (produto_idproduto, fornecedor_idfornecedor, preco_comprar, prazo_fornecimento)
VALUES
    (39, 18, 54.76, 30),
    (40, 40, 190.01, 21),
    (40, 36, 210.83, 14),
    (40, 26, 229.49, 3),
    (41, 33, 36.05, 10),
    (41, 6, 39.97, 15),
    (42, 9, 38.43, 1),
    (42, 7, 34.99, 7),
    (43, 18, 38.08, 14),
    (44, 34, 43.66, 1);

INSERT INTO produto_fornecedor
    (produto_idproduto, fornecedor_idfornecedor, preco_comprar, prazo_fornecimento)
VALUES
    (44, 11, 51.06, 3),
    (44, 13, 40.14, 1),
    (45, 34, 30.79, 15),
    (46, 11, 31.14, 3),
    (46, 31, 28.38, 21),
    (47, 15, 83.89, 30),
    (47, 2, 78.77, 7),
    (47, 12, 83.56, 14),
    (48, 31, 54.91, 15),
    (49, 28, 128.26, 3);

INSERT INTO produto_fornecedor
    (produto_idproduto, fornecedor_idfornecedor, preco_comprar, prazo_fornecimento)
VALUES
    (50, 17, 82.24, 21),
    (51, 5, 160.21, 10),
    (52, 40, 24.09, 7),
    (52, 27, 26.86, 15),
    (52, 19, 28.77, 30),
    (53, 15, 17.63, 3),
    (54, 30, 46.74, 2),
    (55, 3, 100.58, 21),
    (55, 23, 100.98, 7),
    (55, 25, 110.90, 7);

INSERT INTO produto_fornecedor
    (produto_idproduto, fornecedor_idfornecedor, preco_comprar, prazo_fornecimento)
VALUES
    (56, 23, 39.93, 14),
    (56, 9, 33.81, 1),
    (56, 36, 40.63, 7),
    (57, 30, 31.08, 7),
    (57, 2, 33.00, 7),
    (58, 16, 30.29, 10);

-- =========================================================
-- PEDIDO
-- =========================================================
INSERT INTO pedido
    (idpedido, data_pedido, status, cliente_pessoa_idpessoa)
VALUES
    (1, '2026-01-01 08:15:00', 'ABERTO', 62),
    (2, '2026-01-03 12:15:00', 'ENVIADO', 100),
    (3, '2026-01-11 14:15:00', 'ENVIADO', 86),
    (4, '2026-01-14 14:50:00', 'CANCELADO', 86),
    (5, '2026-01-26 17:40:00', 'ENVIADO', 58),
    (6, '2026-02-03 17:00:00', 'PAGO', 43),
    (7, '2026-02-14 09:20:00', 'ENVIADO', 66),
    (8, '2026-02-20 10:15:00', 'PAGO', 72),
    (9, '2026-02-21 14:50:00', 'PAGO', 61),
    (10, '2026-03-03 17:50:00', 'ABERTO', 58);

INSERT INTO pedido
    (idpedido, data_pedido, status, cliente_pessoa_idpessoa)
VALUES
    (11, '2026-03-04 18:45:00', 'PAGO', 61),
    (12, '2026-03-06 17:50:00', 'ABERTO', 98),
    (13, '2026-03-22 10:45:00', 'ABERTO', 73),
    (14, '2026-03-24 08:40:00', 'ENVIADO', 78),
    (15, '2026-03-26 13:20:00', 'ABERTO', 65),
    (16, '2026-04-02 16:40:00', 'PAGO', 47),
    (17, '2026-04-03 09:15:00', 'ABERTO', 72),
    (18, '2026-04-03 09:20:00', 'PAGO', 59),
    (19, '2026-04-03 13:40:00', 'ENVIADO', 58),
    (20, '2026-04-04 12:50:00', 'PAGO', 58);

INSERT INTO pedido
    (idpedido, data_pedido, status, cliente_pessoa_idpessoa)
VALUES
    (21, '2026-04-07 11:50:00', 'ENVIADO', 47),
    (22, '2026-04-12 14:00:00', 'ENVIADO', 67),
    (23, '2026-04-12 14:15:00', 'PAGO', 48),
    (24, '2026-04-12 18:15:00', 'PAGO', 60),
    (25, '2026-04-16 12:30:00', 'CANCELADO', 94),
    (26, '2026-04-23 16:20:00', 'ABERTO', 95),
    (27, '2026-05-01 11:40:00', 'ENVIADO', 60),
    (28, '2026-05-01 17:45:00', 'PAGO', 62),
    (29, '2026-05-05 11:50:00', 'PAGO', 86),
    (30, '2026-05-13 09:40:00', 'ENVIADO', 65);

INSERT INTO pedido
    (idpedido, data_pedido, status, cliente_pessoa_idpessoa)
VALUES
    (31, '2026-05-14 10:15:00', 'PAGO', 58),
    (32, '2026-05-16 11:40:00', 'PAGO', 73),
    (33, '2026-05-20 10:15:00', 'PAGO', 66),
    (34, '2026-05-26 13:45:00', 'ENVIADO', 53),
    (35, '2026-05-27 16:20:00', 'ENVIADO', 60),
    (36, '2026-06-08 18:45:00', 'PAGO', 47),
    (37, '2026-06-10 10:45:00', 'ENVIADO', 95),
    (38, '2026-06-15 16:40:00', 'ENVIADO', 72),
    (39, '2026-06-16 15:30:00', 'CANCELADO', 83),
    (40, '2026-06-19 08:40:00', 'ENVIADO', 64);

INSERT INTO pedido
    (idpedido, data_pedido, status, cliente_pessoa_idpessoa)
VALUES
    (41, '2026-06-23 15:15:00', 'ABERTO', 57),
    (42, '2026-06-25 14:40:00', 'CANCELADO', 68),
    (43, '2026-06-28 14:10:00', 'PAGO', 88),
    (44, '2026-07-05 15:10:00', 'ENVIADO', 100),
    (45, '2026-07-05 18:40:00', 'ENVIADO', 77),
    (46, '2026-07-12 17:15:00', 'PAGO', 85),
    (47, '2026-07-21 08:30:00', 'ENVIADO', 100),
    (48, '2026-07-21 10:40:00', 'PAGO', 58),
    (49, '2026-07-22 08:20:00', 'ABERTO', 55),
    (50, '2026-07-22 08:30:00', 'ENVIADO', 57);

INSERT INTO pedido
    (idpedido, data_pedido, status, cliente_pessoa_idpessoa)
VALUES
    (51, '2026-07-25 13:40:00', 'PAGO', 65),
    (52, '2026-07-27 08:00:00', 'ABERTO', 65),
    (53, '2026-08-13 17:10:00', 'CANCELADO', 43),
    (54, '2026-08-19 17:15:00', 'ENVIADO', 59),
    (55, '2026-08-20 13:20:00', 'PAGO', 60),
    (56, '2026-08-20 17:10:00', 'PAGO', 43),
    (57, '2026-08-20 17:30:00', 'ENVIADO', 81),
    (58, '2026-08-21 12:20:00', 'ENVIADO', 46),
    (59, '2026-08-24 10:00:00', 'ENVIADO', 103),
    (60, '2026-08-27 15:10:00', 'CANCELADO', 47);

INSERT INTO pedido
    (idpedido, data_pedido, status, cliente_pessoa_idpessoa)
VALUES
    (61, '2026-09-05 08:00:00', 'ENVIADO', 59),
    (62, '2026-09-08 14:40:00', 'ENVIADO', 63),
    (63, '2026-09-08 16:00:00', 'PAGO', 43),
    (64, '2026-09-12 09:40:00', 'ENVIADO', 72),
    (65, '2026-09-12 10:15:00', 'ENVIADO', 65),
    (66, '2026-09-01 14:00:00', 'ENVIADO', 80),
    (67, '2026-09-08 14:00:00', 'ENVIADO', 86),
    (68, '2026-09-14 14:00:00', 'CANCELADO', 46),
    (69, '2026-09-05 14:00:00', 'ENVIADO', 98),
    (70, '2026-09-11 14:00:00', 'CANCELADO', 91);

-- =========================================================
-- ITEM_PEDIDO
-- O preco_unitario é o valor cobrado no dia da venda, por isso em
-- alguns itens ele não bate com o preco_venda atual do produto.
-- =========================================================
INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (1, 36, 12, 12.12),
    (1, 19, 1, 8.20),
    (2, 27, 2, 96.00),
    (3, 8, 2, 16.40),
    (3, 15, 6, 54.00),
    (4, 30, 2, 78.00),
    (4, 52, 1, 38.90),
    (4, 12, 6, 52.00),
    (4, 16, 3, 8.90),
    (4, 31, 2, 56.37),
    (5, 52, 2, 38.90),
    (6, 42, 5, 59.90);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (6, 22, 5, 17.90),
    (6, 1, 2, 47.90),
    (6, 54, 10, 64.90),
    (7, 5, 12, 14.50),
    (7, 52, 1, 38.90),
    (7, 38, 6, 58.90),
    (7, 39, 2, 74.90),
    (8, 48, 6, 79.90),
    (9, 29, 1, 16.90),
    (9, 16, 2, 8.90),
    (9, 30, 12, 78.00),
    (9, 49, 6, 189.00);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (9, 50, 12, 120.86),
    (10, 53, 4, 21.39),
    (10, 7, 4, 10.79),
    (10, 6, 12, 67.09),
    (11, 57, 10, 47.00),
    (11, 14, 3, 38.90),
    (11, 59, 2, 18.90),
    (11, 31, 1, 62.00),
    (12, 53, 10, 24.90),
    (12, 18, 5, 8.20),
    (12, 49, 2, 189.00),
    (13, 45, 2, 43.64);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (13, 12, 5, 52.00),
    (13, 29, 2, 15.03),
    (13, 16, 4, 8.90),
    (14, 32, 6, 19.90),
    (14, 16, 10, 9.26),
    (14, 17, 2, 36.50),
    (15, 26, 1, 27.90),
    (15, 10, 1, 18.90),
    (15, 57, 4, 47.00),
    (15, 18, 4, 8.20),
    (15, 38, 1, 58.90),
    (16, 48, 3, 79.90);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (16, 50, 10, 129.90),
    (17, 60, 5, 12.00),
    (17, 35, 10, 67.70),
    (17, 40, 12, 312.00),
    (18, 13, 3, 9.49),
    (18, 56, 2, 54.90),
    (18, 14, 5, 38.90),
    (19, 10, 3, 18.90),
    (19, 45, 1, 49.90),
    (19, 53, 2, 22.77),
    (20, 56, 5, 54.90),
    (20, 30, 12, 78.00);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (21, 44, 1, 63.24),
    (21, 41, 1, 62.00),
    (22, 18, 2, 8.20),
    (22, 56, 2, 57.33),
    (23, 50, 5, 129.90),
    (23, 21, 3, 36.50),
    (23, 32, 4, 19.90),
    (23, 6, 2, 78.00),
    (23, 60, 12, 11.00),
    (24, 48, 6, 79.90),
    (24, 14, 1, 38.90),
    (25, 17, 6, 34.17);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (25, 4, 2, 89.90),
    (25, 2, 4, 119.90),
    (25, 19, 1, 8.20),
    (26, 7, 2, 12.75),
    (26, 32, 3, 19.90),
    (26, 5, 2, 14.50),
    (27, 44, 1, 68.00),
    (27, 34, 6, 12.90),
    (28, 12, 12, 52.00),
    (28, 7, 4, 11.90),
    (28, 14, 5, 38.90),
    (29, 49, 1, 189.00);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (29, 22, 6, 17.90),
    (30, 30, 2, 78.00),
    (31, 57, 5, 47.00),
    (31, 25, 2, 21.90),
    (31, 18, 12, 8.20),
    (31, 28, 2, 21.50),
    (32, 6, 1, 78.00),
    (32, 28, 12, 22.64),
    (33, 60, 10, 10.87),
    (33, 29, 10, 16.90),
    (33, 34, 5, 12.90),
    (33, 25, 12, 21.90);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (33, 44, 10, 68.00),
    (34, 34, 4, 12.90),
    (34, 5, 6, 14.50),
    (35, 51, 6, 219.00),
    (35, 43, 4, 54.00),
    (35, 53, 2, 24.90),
    (36, 60, 6, 11.02),
    (36, 42, 2, 59.90),
    (37, 40, 2, 294.23),
    (37, 31, 5, 62.00),
    (37, 56, 2, 50.64),
    (38, 55, 2, 148.00);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (38, 41, 1, 62.00),
    (38, 52, 12, 40.40),
    (39, 29, 3, 16.90),
    (39, 50, 6, 129.90),
    (39, 31, 1, 62.00),
    (39, 3, 2, 9.80),
    (39, 39, 6, 74.90),
    (40, 21, 5, 36.50),
    (40, 19, 4, 8.20),
    (41, 49, 2, 189.00),
    (41, 17, 2, 37.89),
    (41, 39, 2, 74.90);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (42, 41, 5, 62.00),
    (42, 13, 5, 9.49),
    (42, 14, 2, 38.90),
    (43, 27, 4, 96.00),
    (43, 51, 12, 189.93),
    (43, 48, 1, 79.90),
    (43, 22, 4, 17.90),
    (44, 28, 10, 24.90),
    (44, 25, 4, 19.29),
    (44, 13, 3, 9.49),
    (45, 40, 5, 312.00),
    (45, 2, 1, 119.90);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (46, 59, 10, 18.90),
    (46, 33, 5, 168.00),
    (46, 6, 6, 78.00),
    (46, 25, 12, 21.90),
    (47, 21, 3, 36.50),
    (47, 49, 5, 189.00),
    (47, 1, 1, 41.01),
    (48, 52, 2, 40.82),
    (48, 48, 12, 79.90),
    (48, 32, 3, 19.90),
    (49, 9, 12, 167.00),
    (49, 27, 3, 90.47);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (49, 25, 5, 21.90),
    (50, 5, 2, 14.50),
    (50, 9, 6, 167.00),
    (50, 16, 12, 8.90),
    (50, 36, 2, 12.39),
    (51, 35, 4, 71.90),
    (51, 38, 2, 58.90),
    (52, 60, 1, 10.62),
    (52, 10, 2, 18.90),
    (53, 56, 1, 48.22),
    (54, 27, 12, 96.00),
    (54, 46, 4, 44.57);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (55, 37, 2, 54.00),
    (55, 27, 2, 99.20),
    (55, 15, 3, 58.04),
    (55, 30, 12, 72.90),
    (56, 41, 3, 62.00),
    (56, 11, 6, 89.00),
    (56, 39, 10, 74.90),
    (57, 35, 1, 71.90),
    (58, 29, 2, 15.41),
    (58, 60, 10, 12.00),
    (58, 44, 12, 58.03),
    (59, 24, 4, 22.00);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (59, 32, 5, 19.90),
    (60, 15, 2, 54.00),
    (60, 44, 2, 68.00),
    (60, 1, 3, 47.90),
    (60, 22, 2, 19.16),
    (60, 45, 6, 49.90),
    (61, 34, 1, 12.90),
    (61, 22, 2, 17.90),
    (61, 6, 1, 78.00),
    (62, 43, 3, 46.45),
    (63, 39, 12, 74.90),
    (63, 37, 5, 56.36);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (63, 6, 3, 69.91),
    (64, 48, 2, 73.03),
    (64, 8, 1, 16.40),
    (65, 56, 12, 54.90),
    (65, 39, 5, 74.90),
    (66, 20, 4, 9.49),
    (66, 55, 10, 127.79),
    (66, 29, 5, 14.85),
    (67, 55, 6, 148.00),
    (67, 43, 5, 54.00),
    (68, 22, 10, 17.90),
    (69, 46, 6, 42.90);

INSERT INTO item_pedido
    (pedido_idpedido, produto_idproduto, quantidade, preco_unitario)
VALUES
    (69, 60, 12, 12.00),
    (69, 36, 3, 11.50),
    (69, 7, 2, 11.90),
    (69, 57, 3, 47.00),
    (70, 17, 4, 31.59),
    (70, 56, 2, 54.90),
    (70, 54, 4, 64.90);

-- =========================================================
-- PAGAMENTO
-- Um pagamento por pedido. Pedido em aberto fica PENDENTE e
-- cancelado fica PENDENTE ou RECUSADO, sempre sem data.
-- =========================================================
INSERT INTO pagamento
    (idpagamento, forma_pagamento, status_pagamento, data_pagamento, pedido_idpedido)
VALUES
    (1, 'PIX', 'PENDENTE', NULL, 1),
    (2, 'Cartão de Débito', 'APROVADO', '2026-01-03 18:15:00', 2),
    (3, 'Boleto Bancário', 'APROVADO', '2026-01-12 18:15:00', 3),
    (4, 'PIX', 'PENDENTE', NULL, 4),
    (5, 'PIX', 'APROVADO', '2026-01-26 18:40:00', 5),
    (6, 'Transferência Bancária', 'APROVADO', '2026-02-05 01:00:00', 6),
    (7, 'Cartão de Débito', 'APROVADO', '2026-02-16 13:20:00', 7),
    (8, 'PIX', 'APROVADO', '2026-02-20 11:15:00', 8),
    (9, 'PIX', 'APROVADO', '2026-02-21 18:50:00', 9),
    (10, 'Cartão de Débito', 'PENDENTE', NULL, 10);

INSERT INTO pagamento
    (idpagamento, forma_pagamento, status_pagamento, data_pagamento, pedido_idpedido)
VALUES
    (11, 'Boleto Bancário', 'APROVADO', '2026-03-05 00:45:00', 11),
    (12, 'Dinheiro', 'PENDENTE', NULL, 12),
    (13, 'Cartão de Débito', 'PENDENTE', NULL, 13),
    (14, 'Dinheiro', 'APROVADO', '2026-03-26 14:40:00', 14),
    (15, 'Boleto Bancário', 'PENDENTE', NULL, 15),
    (16, 'Dinheiro', 'APROVADO', '2026-04-02 18:40:00', 16),
    (17, 'Cartão de Crédito', 'PENDENTE', NULL, 17),
    (18, 'Boleto Bancário', 'APROVADO', '2026-04-05 15:20:00', 18),
    (19, 'Cartão de Débito', 'APROVADO', '2026-04-03 20:40:00', 19),
    (20, 'Boleto Bancário', 'APROVADO', '2026-04-06 13:50:00', 20);

INSERT INTO pagamento
    (idpagamento, forma_pagamento, status_pagamento, data_pagamento, pedido_idpedido)
VALUES
    (21, 'Cartão de Crédito', 'APROVADO', '2026-04-07 14:50:00', 21),
    (22, 'Dinheiro', 'APROVADO', '2026-04-13 20:00:00', 22),
    (23, 'Cartão de Débito', 'APROVADO', '2026-04-12 21:15:00', 23),
    (24, 'Boleto Bancário', 'APROVADO', '2026-04-13 22:15:00', 24),
    (25, 'Cartão de Crédito', 'RECUSADO', NULL, 25),
    (26, 'Cartão de Crédito', 'PENDENTE', NULL, 26),
    (27, 'Cartão de Débito', 'APROVADO', '2026-05-01 13:40:00', 27),
    (28, 'Boleto Bancário', 'APROVADO', '2026-05-02 00:45:00', 28),
    (29, 'PIX', 'APROVADO', '2026-05-05 14:50:00', 29),
    (30, 'Cartão de Crédito', 'APROVADO', '2026-05-13 17:40:00', 30);

INSERT INTO pagamento
    (idpagamento, forma_pagamento, status_pagamento, data_pagamento, pedido_idpedido)
VALUES
    (31, 'Transferência Bancária', 'APROVADO', '2026-05-16 16:15:00', 31),
    (32, 'Boleto Bancário', 'APROVADO', '2026-05-16 18:40:00', 32),
    (33, 'Cartão de Crédito', 'APROVADO', '2026-05-22 18:15:00', 33),
    (34, 'Cartão de Débito', 'APROVADO', '2026-05-28 20:45:00', 34),
    (35, 'Cartão de Débito', 'APROVADO', '2026-05-27 19:20:00', 35),
    (36, 'PIX', 'APROVADO', '2026-06-09 19:45:00', 36),
    (37, 'Dinheiro', 'APROVADO', '2026-06-12 16:45:00', 37),
    (38, 'Transferência Bancária', 'APROVADO', '2026-06-15 17:40:00', 38),
    (39, 'PIX', 'RECUSADO', NULL, 39),
    (40, 'PIX', 'APROVADO', '2026-06-19 16:40:00', 40);

INSERT INTO pagamento
    (idpagamento, forma_pagamento, status_pagamento, data_pagamento, pedido_idpedido)
VALUES
    (41, 'Dinheiro', 'PENDENTE', NULL, 41),
    (42, 'Dinheiro', 'PENDENTE', NULL, 42),
    (43, 'Transferência Bancária', 'APROVADO', '2026-06-28 21:10:00', 43),
    (44, 'Cartão de Débito', 'APROVADO', '2026-07-05 18:10:00', 44),
    (45, 'Boleto Bancário', 'APROVADO', '2026-07-07 00:40:00', 45),
    (46, 'Boleto Bancário', 'APROVADO', '2026-07-12 21:15:00', 46),
    (47, 'Boleto Bancário', 'APROVADO', '2026-07-22 15:30:00', 47),
    (48, 'Cartão de Crédito', 'APROVADO', '2026-07-21 15:40:00', 48),
    (49, 'PIX', 'PENDENTE', NULL, 49),
    (50, 'PIX', 'APROVADO', '2026-07-23 12:30:00', 50);

INSERT INTO pagamento
    (idpagamento, forma_pagamento, status_pagamento, data_pagamento, pedido_idpedido)
VALUES
    (51, 'Cartão de Crédito', 'APROVADO', '2026-07-25 19:40:00', 51),
    (52, 'Dinheiro', 'PENDENTE', NULL, 52),
    (53, 'Cartão de Débito', 'RECUSADO', NULL, 53),
    (54, 'Dinheiro', 'APROVADO', '2026-08-20 18:15:00', 54),
    (55, 'Cartão de Crédito', 'APROVADO', '2026-08-20 17:20:00', 55),
    (56, 'Cartão de Crédito', 'APROVADO', '2026-08-22 20:10:00', 56),
    (57, 'Cartão de Débito', 'APROVADO', '2026-08-20 18:30:00', 57),
    (58, 'Boleto Bancário', 'APROVADO', '2026-08-23 14:20:00', 58),
    (59, 'Dinheiro', 'APROVADO', '2026-08-24 11:00:00', 59),
    (60, 'Boleto Bancário', 'PENDENTE', NULL, 60);

INSERT INTO pagamento
    (idpagamento, forma_pagamento, status_pagamento, data_pagamento, pedido_idpedido)
VALUES
    (61, 'Dinheiro', 'APROVADO', '2026-09-06 14:00:00', 61),
    (62, 'Dinheiro', 'APROVADO', '2026-09-08 16:40:00', 62),
    (63, 'Dinheiro', 'APROVADO', '2026-09-08 21:00:00', 63),
    (64, 'Dinheiro', 'APROVADO', '2026-09-12 15:40:00', 64),
    (65, 'PIX', 'APROVADO', '2026-09-14 13:15:00', 65),
    (66, 'Transferência Bancária', 'APROVADO', '2026-09-01 16:00:00', 66),
    (67, 'PIX', 'APROVADO', '2026-09-09 21:00:00', 67),
    (68, 'Cartão de Crédito', 'PENDENTE', NULL, 68),
    (69, 'PIX', 'APROVADO', '2026-09-05 22:00:00', 69),
    (70, 'Cartão de Crédito', 'PENDENTE', NULL, 70);

-- =========================================================
-- ENTREGA
-- Só os pedidos já pagos geram entrega. A data de entrega só é
-- preenchida quando o status é ENTREGUE.
-- =========================================================
INSERT INTO entrega
    (identrega, data_prevista, data_entrega, status_entrega, pedido_idpedido, funcionario_pessoa_idpessoa)
VALUES
    (1, '2026-01-06', '2026-01-06', 'ENTREGUE', 2, 24),
    (2, '2026-01-13', '2026-01-15', 'ENTREGUE', 3, 42),
    (3, '2026-01-31', NULL, 'EM_ROTA', 5, 33),
    (4, '2026-02-16', '2026-02-16', 'ENTREGUE', 7, 42),
    (5, '2026-02-27', NULL, 'PENDENTE', 8, NULL),
    (6, '2026-03-08', NULL, 'PENDENTE', 11, NULL),
    (7, '2026-03-28', '2026-03-27', 'ENTREGUE', 14, 33),
    (8, '2026-04-06', '2026-04-06', 'ENTREGUE', 19, 12),
    (9, '2026-04-10', NULL, 'PENDENTE', 20, NULL),
    (10, '2026-04-11', '2026-04-11', 'ENTREGUE', 21, 12);

INSERT INTO entrega
    (identrega, data_prevista, data_entrega, status_entrega, pedido_idpedido, funcionario_pessoa_idpessoa)
VALUES
    (11, '2026-04-18', NULL, 'EM_ROTA', 22, 42),
    (12, '2026-04-18', NULL, 'PENDENTE', 23, NULL),
    (13, '2026-05-06', NULL, 'EM_ROTA', 27, NULL),   -- saiu para entrega sem motorista definido
    (14, '2026-05-13', NULL, 'PENDENTE', 29, NULL),
    (15, '2026-05-17', '2026-05-17', 'ENTREGUE', 30, 12),
    (16, '2026-05-21', NULL, 'PENDENTE', 31, NULL),
    (17, '2026-05-23', NULL, 'PENDENTE', 32, NULL),
    (18, '2026-05-30', '2026-05-30', 'ENTREGUE', 34, 31),
    (19, '2026-05-30', NULL, 'EM_ROTA', 35, 31),
    (20, '2026-06-15', NULL, 'PENDENTE', 36, NULL);

INSERT INTO entrega
    (identrega, data_prevista, data_entrega, status_entrega, pedido_idpedido, funcionario_pessoa_idpessoa)
VALUES
    (21, '2026-06-14', NULL, 'EM_ROTA', 37, 25),
    (22, '2026-06-17', '2026-06-18', 'ENTREGUE', 38, 31),
    (23, '2026-06-21', NULL, 'EM_ROTA', 40, 25),
    (24, '2026-07-04', NULL, 'PENDENTE', 43, NULL),
    (25, '2026-07-10', '2026-07-10', 'ENTREGUE', 44, 25),
    (26, '2026-07-08', '2026-07-09', 'ENTREGUE', 45, 25),
    (27, '2026-07-19', NULL, 'PENDENTE', 46, NULL),
    (28, '2026-07-25', '2026-07-24', 'ENTREGUE', 47, 33),
    (29, '2026-07-24', NULL, 'PENDENTE', 48, NULL),
    (30, '2026-07-25', '2026-07-25', 'ENTREGUE', 50, 42);

INSERT INTO entrega
    (identrega, data_prevista, data_entrega, status_entrega, pedido_idpedido, funcionario_pessoa_idpessoa)
VALUES
    (31, '2026-08-22', NULL, 'EM_ROTA', 54, 24),
    (32, '2026-08-25', NULL, 'PENDENTE', 56, NULL),
    (33, '2026-08-25', '2026-08-24', 'ENTREGUE', 57, 24),
    (34, '2026-08-24', '2026-08-23', 'ENTREGUE', 58, 42),
    (35, '2026-08-26', NULL, 'EM_ROTA', 59, 12),
    (36, '2026-09-11', '2026-09-13', 'ENTREGUE', 61, 42),
    (37, '2026-09-12', '2026-09-13', 'ENTREGUE', 62, 24),
    (38, '2026-09-15', NULL, 'EM_ROTA', 64, 42),
    (39, '2026-09-15', '2026-09-15', 'ENTREGUE', 65, 31),
    (40, '2026-09-03', '2026-09-02', 'ENTREGUE', 66, 24);

INSERT INTO entrega
    (identrega, data_prevista, data_entrega, status_entrega, pedido_idpedido, funcionario_pessoa_idpessoa)
VALUES
    (41, '2026-09-13', '2026-09-12', 'ENTREGUE', 67, 33),
    (42, '2026-09-10', NULL, 'EM_ROTA', 69, 25);

-- =========================================================
-- ESTOQUE
-- A quantidade_atual é o resultado das entradas menos as saídas
-- registradas na movimentação (RN09 e RN11).
-- =========================================================
INSERT INTO estoque
    (idestoque, produto_idproduto, quantidade_atual, data_atualizacao)
VALUES
    (1, 1, 4, '2026-07-21 23:30:00'),
    (2, 2, 6, '2026-07-09 15:15:00'),
    (3, 3, 24, '2025-11-04 09:10:00'),
    (4, 4, 48, '2025-11-11 09:20:00'),
    (5, 5, 3, '2026-07-22 10:30:00'),
    (6, 6, 3, '2026-09-08 20:00:00'),
    (7, 7, 2, '2026-09-05 22:00:00'),
    (8, 8, 4, '2026-09-12 22:40:00'),
    (9, 9, 3, '2026-07-23 00:30:00'),
    (10, 10, 2, '2026-07-27 12:00:00');

INSERT INTO estoque
    (idestoque, produto_idproduto, quantidade_atual, data_atualizacao)
VALUES
    (11, 11, 2, '2026-08-20 23:10:00'),
    (12, 12, 0, '2026-05-02 01:45:00'),   -- produto zerado
    (13, 13, 2, '2026-07-18 15:50:00'),
    (14, 14, 13, '2026-07-05 11:20:00'),
    (15, 15, 2, '2026-08-21 02:20:00'),
    (16, 16, 2, '2026-07-23 00:30:00'),
    (17, 17, 2, '2026-06-24 04:15:00'),
    (18, 18, 8, '2026-06-16 09:10:00'),
    (19, 19, 2, '2026-06-24 13:15:00'),
    (20, 20, 2, '2026-09-01 19:00:00');

INSERT INTO estoque
    (idestoque, produto_idproduto, quantidade_atual, data_atualizacao)
VALUES
    (21, 21, 2, '2026-07-21 12:30:00'),
    (22, 22, 3, '2026-09-05 20:00:00'),
    (23, 23, 24, '2025-11-12 07:30:00'),
    (24, 24, 2, '2026-08-24 20:00:00'),
    (25, 25, 2, '2026-07-22 11:20:00'),
    (26, 26, 0, '2026-03-27 07:20:00'),   -- produto zerado
    (27, 27, 2, '2026-08-20 19:20:00'),
    (28, 28, 3, '2026-07-06 04:10:00'),
    (29, 29, 4, '2026-09-01 18:00:00'),
    (30, 30, 7, '2026-08-20 19:20:00');

INSERT INTO estoque
    (idestoque, produto_idproduto, quantidade_atual, data_atualizacao)
VALUES
    (31, 31, 2, '2026-07-22 16:15:00'),
    (32, 32, 3, '2026-08-24 13:00:00'),
    (33, 33, 2, '2026-07-12 23:15:00'),
    (34, 34, 22, '2026-09-05 15:00:00'),
    (35, 35, 3, '2026-08-20 21:30:00'),
    (36, 36, 26, '2026-09-05 17:00:00'),
    (37, 37, 2, '2026-09-09 12:00:00'),
    (38, 38, 2, '2026-07-26 02:40:00'),
    (39, 39, 2, '2026-09-13 03:15:00'),
    (40, 40, 2, '2026-07-06 09:40:00');

INSERT INTO estoque
    (idestoque, produto_idproduto, quantidade_atual, data_atualizacao)
VALUES
    (41, 41, 2, '2026-08-21 04:10:00'),
    (42, 42, 2, '2026-06-09 08:45:00'),
    (43, 43, 2, '2026-09-09 10:40:00'),
    (44, 44, 2, '2026-08-21 13:20:00'),
    (45, 45, 3, '2026-04-03 18:40:00'),
    (46, 46, 2, '2026-09-05 23:00:00'),
    (47, 47, 48, '2025-11-16 07:50:00'),
    (48, 48, 7, '2026-09-13 01:40:00'),
    (49, 49, 3, '2026-07-21 22:30:00'),
    (50, 50, 16, '2026-07-03 15:15:00');

INSERT INTO estoque
    (idestoque, produto_idproduto, quantidade_atual, data_atualizacao)
VALUES
    (51, 51, 6, '2026-07-25 18:10:00'),
    (52, 52, 2, '2026-07-22 03:40:00'),
    (53, 53, 21, '2026-05-28 01:20:00'),
    (54, 54, 22, '2026-06-22 18:40:00'),
    (55, 55, 3, '2026-09-08 17:00:00'),
    (56, 56, 4, '2026-09-12 23:15:00'),
    (57, 57, 15, '2026-09-06 04:00:00'),
    (58, 58, 36, '2025-11-10 09:00:00'),
    (59, 59, 3, '2026-07-13 06:15:00'),
    (60, 60, 5, '2026-09-05 21:00:00');

-- =========================================================
-- MOVIMENTACAO_ESTOQUE
-- Tabela de maior volume da carga. As entradas vêm das compras e as
-- saídas dos pedidos que não foram cancelados.
-- =========================================================
INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (1, 'ENTRADA', 1, '2025-11-03 07:00:00', 26),
    (2, 'ENTRADA', 10, '2025-11-03 07:10:00', 48),
    (3, 'ENTRADA', 7, '2025-11-03 10:45:00', 22),
    (4, 'ENTRADA', 24, '2025-11-04 09:10:00', 3),
    (5, 'ENTRADA', 6, '2025-11-04 09:45:00', 46),
    (6, 'ENTRADA', 7, '2025-11-04 10:45:00', 18),
    (7, 'ENTRADA', 10, '2025-11-05 10:30:00', 5),
    (8, 'ENTRADA', 6, '2025-11-05 10:30:00', 31),
    (9, 'ENTRADA', 10, '2025-11-06 09:30:00', 50),
    (10, 'ENTRADA', 6, '2025-11-06 09:50:00', 43),
    (11, 'ENTRADA', 6, '2025-11-06 10:10:00', 24),
    (12, 'ENTRADA', 6, '2025-11-07 08:15:00', 10);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (13, 'ENTRADA', 6, '2025-11-07 08:40:00', 45),
    (14, 'ENTRADA', 9, '2025-11-07 09:45:00', 57),
    (15, 'ENTRADA', 6, '2025-11-09 08:10:00', 17),
    (16, 'ENTRADA', 9, '2025-11-09 08:15:00', 32),
    (17, 'ENTRADA', 6, '2025-11-09 09:00:00', 52),
    (18, 'ENTRADA', 6, '2025-11-09 11:15:00', 41),
    (19, 'ENTRADA', 8, '2025-11-09 11:50:00', 36),
    (20, 'ENTRADA', 10, '2025-11-10 07:30:00', 6),
    (21, 'ENTRADA', 22, '2025-11-10 08:10:00', 60),
    (22, 'ENTRADA', 36, '2025-11-10 09:00:00', 58),
    (23, 'ENTRADA', 8, '2025-11-10 10:30:00', 27),
    (24, 'ENTRADA', 6, '2025-11-11 07:40:00', 59);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (25, 'ENTRADA', 8, '2025-11-11 08:20:00', 16),
    (26, 'ENTRADA', 7, '2025-11-11 08:20:00', 35),
    (27, 'ENTRADA', 48, '2025-11-11 09:20:00', 4),
    (28, 'ENTRADA', 17, '2025-11-11 11:50:00', 12),
    (29, 'ENTRADA', 6, '2025-11-12 07:15:00', 1),
    (30, 'ENTRADA', 24, '2025-11-12 07:30:00', 23),
    (31, 'ENTRADA', 18, '2025-11-12 09:50:00', 30),
    (32, 'ENTRADA', 10, '2025-11-12 10:45:00', 28),
    (33, 'ENTRADA', 6, '2025-11-13 09:15:00', 11),
    (34, 'ENTRADA', 8, '2025-11-13 11:40:00', 9),
    (35, 'ENTRADA', 6, '2025-11-14 09:45:00', 40),
    (36, 'ENTRADA', 7, '2025-11-14 10:30:00', 55);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (37, 'ENTRADA', 7, '2025-11-14 10:40:00', 44),
    (38, 'ENTRADA', 6, '2025-11-14 10:40:00', 53),
    (39, 'ENTRADA', 7, '2025-11-15 08:50:00', 34),
    (40, 'ENTRADA', 9, '2025-11-15 08:50:00', 39),
    (41, 'ENTRADA', 9, '2025-11-15 09:45:00', 29),
    (42, 'ENTRADA', 6, '2025-11-15 11:45:00', 33),
    (43, 'ENTRADA', 48, '2025-11-16 07:50:00', 47),
    (44, 'ENTRADA', 6, '2025-11-16 10:50:00', 20),
    (45, 'ENTRADA', 6, '2025-11-18 07:10:00', 37),
    (46, 'ENTRADA', 6, '2025-11-18 07:20:00', 21),
    (47, 'ENTRADA', 6, '2025-11-18 07:45:00', 7),
    (48, 'ENTRADA', 6, '2025-11-18 08:30:00', 13);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (49, 'ENTRADA', 7, '2025-11-18 08:45:00', 49),
    (50, 'ENTRADA', 6, '2025-11-19 07:20:00', 15),
    (51, 'ENTRADA', 9, '2025-11-19 07:50:00', 56),
    (52, 'ENTRADA', 6, '2025-11-19 08:45:00', 51),
    (53, 'ENTRADA', 6, '2025-11-19 10:40:00', 42),
    (54, 'ENTRADA', 6, '2025-11-19 11:40:00', 38),
    (55, 'ENTRADA', 6, '2025-11-19 11:45:00', 2),
    (56, 'ENTRADA', 6, '2025-11-20 07:10:00', 54),
    (57, 'ENTRADA', 6, '2025-11-20 07:45:00', 19),
    (58, 'ENTRADA', 12, '2025-11-20 08:40:00', 25),
    (59, 'ENTRADA', 6, '2025-11-20 09:15:00', 8),
    (60, 'ENTRADA', 6, '2025-11-20 10:30:00', 14);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (61, 'ENTRADA', 22, '2026-01-01 03:15:00', 36),
    (62, 'ENTRADA', 2, '2026-01-01 08:00:00', 21),
    (63, 'ENTRADA', 4, '2026-01-01 09:30:00', 9),
    (64, 'SAIDA', 1, '2026-01-01 11:15:00', 19),
    (65, 'SAIDA', 12, '2026-01-02 03:15:00', 36),
    (66, 'ENTRADA', 4, '2026-01-02 08:50:00', 6),
    (67, 'ENTRADA', 6, '2026-01-02 14:45:00', 18),
    (68, 'SAIDA', 2, '2026-01-03 16:15:00', 27),
    (69, 'ENTRADA', 5, '2026-01-03 18:20:00', 40),
    (70, 'ENTRADA', 5, '2026-01-03 18:40:00', 5),
    (71, 'ENTRADA', 2, '2026-01-04 16:10:00', 46),
    (72, 'ENTRADA', 2, '2026-01-05 08:00:00', 14);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (73, 'ENTRADA', 3, '2026-01-05 17:15:00', 32),
    (74, 'ENTRADA', 8, '2026-01-05 18:00:00', 39),
    (75, 'ENTRADA', 3, '2026-01-08 13:40:00', 51),
    (76, 'ENTRADA', 1, '2026-01-08 18:20:00', 37),
    (77, 'ENTRADA', 4, '2026-01-08 18:45:00', 50),
    (78, 'ENTRADA', 8, '2026-01-09 08:10:00', 27),
    (79, 'ENTRADA', 3, '2026-01-09 09:15:00', 34),
    (80, 'ENTRADA', 13, '2026-01-11 12:50:00', 48),
    (81, 'ENTRADA', 6, '2026-01-11 14:10:00', 25),
    (82, 'ENTRADA', 9, '2026-01-11 18:15:00', 44),
    (83, 'SAIDA', 2, '2026-01-11 23:15:00', 8),
    (84, 'SAIDA', 6, '2026-01-12 02:15:00', 15);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (85, 'ENTRADA', 1, '2026-01-13 15:15:00', 15),
    (86, 'ENTRADA', 3, '2026-01-13 17:40:00', 59),
    (87, 'ENTRADA', 11, '2026-01-14 10:00:00', 16),
    (88, 'ENTRADA', 2, '2026-01-15 10:00:00', 35),
    (89, 'ENTRADA', 3, '2026-01-16 13:10:00', 52),
    (90, 'ENTRADA', 9, '2026-01-17 17:45:00', 30),
    (91, 'ENTRADA', 3, '2026-01-18 08:15:00', 57),
    (92, 'ENTRADA', 8, '2026-01-18 08:45:00', 28),
    (93, 'ENTRADA', 6, '2026-01-18 09:40:00', 36),
    (94, 'ENTRADA', 3, '2026-01-19 17:15:00', 22),
    (95, 'ENTRADA', 3, '2026-01-20 12:45:00', 55),
    (96, 'ENTRADA', 19, '2026-01-20 18:20:00', 60);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (97, 'ENTRADA', 1, '2026-01-22 11:50:00', 38),
    (98, 'ENTRADA', 3, '2026-01-22 18:00:00', 49),
    (99, 'ENTRADA', 2, '2026-01-23 15:00:00', 54),
    (100, 'ENTRADA', 4, '2026-01-24 17:50:00', 7),
    (101, 'ENTRADA', 7, '2026-01-25 14:00:00', 53),
    (102, 'ENTRADA', 3, '2026-01-26 16:50:00', 29),
    (103, 'SAIDA', 2, '2026-01-27 05:40:00', 52),
    (104, 'ENTRADA', 1, '2026-01-27 13:50:00', 42),
    (105, 'ENTRADA', 4, '2026-01-27 17:45:00', 43),
    (106, 'ENTRADA', 9, '2026-01-28 15:40:00', 56),
    (107, 'ENTRADA', 4, '2026-02-02 09:50:00', 50),
    (108, 'ENTRADA', 20, '2026-02-03 13:00:00', 54);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (109, 'SAIDA', 5, '2026-02-03 19:00:00', 22),
    (110, 'SAIDA', 5, '2026-02-04 11:00:00', 42),
    (111, 'SAIDA', 2, '2026-02-04 13:00:00', 1),
    (112, 'SAIDA', 10, '2026-02-04 13:00:00', 54),
    (113, 'SAIDA', 1, '2026-02-14 20:20:00', 52),
    (114, 'SAIDA', 2, '2026-02-14 22:20:00', 39),
    (115, 'SAIDA', 12, '2026-02-15 00:20:00', 5),
    (116, 'SAIDA', 6, '2026-02-15 03:20:00', 38),
    (117, 'SAIDA', 6, '2026-02-20 21:15:00', 48),
    (118, 'SAIDA', 6, '2026-02-21 15:50:00', 49),
    (119, 'SAIDA', 12, '2026-02-21 17:50:00', 30),
    (120, 'SAIDA', 1, '2026-02-21 23:50:00', 29);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (121, 'SAIDA', 2, '2026-02-22 03:50:00', 16),
    (122, 'SAIDA', 12, '2026-02-22 05:50:00', 50),
    (123, 'ENTRADA', 3, '2026-02-22 13:30:00', 32),
    (124, 'ENTRADA', 2, '2026-03-02 11:45:00', 21),
    (125, 'ENTRADA', 3, '2026-03-02 11:45:00', 51),
    (126, 'ENTRADA', 3, '2026-03-02 13:45:00', 52),
    (127, 'ENTRADA', 5, '2026-03-03 08:00:00', 40),
    (128, 'ENTRADA', 1, '2026-03-03 15:00:00', 38),
    (129, 'SAIDA', 12, '2026-03-03 20:50:00', 6),
    (130, 'SAIDA', 4, '2026-03-04 03:50:00', 53),
    (131, 'SAIDA', 4, '2026-03-04 10:50:00', 7),
    (132, 'SAIDA', 2, '2026-03-04 19:45:00', 59);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (133, 'SAIDA', 1, '2026-03-04 21:45:00', 31),
    (134, 'SAIDA', 3, '2026-03-05 01:45:00', 14),
    (135, 'SAIDA', 10, '2026-03-05 11:45:00', 57),
    (136, 'ENTRADA', 4, '2026-03-05 14:15:00', 9),
    (137, 'ENTRADA', 19, '2026-03-05 18:50:00', 53),
    (138, 'ENTRADA', 3, '2026-03-06 08:20:00', 29),
    (139, 'SAIDA', 2, '2026-03-06 18:50:00', 49),
    (140, 'SAIDA', 10, '2026-03-06 18:50:00', 53),
    (141, 'SAIDA', 5, '2026-03-06 23:50:00', 18),
    (142, 'ENTRADA', 6, '2026-03-07 08:40:00', 18),
    (143, 'ENTRADA', 2, '2026-03-07 10:45:00', 54),
    (144, 'ENTRADA', 1, '2026-03-07 12:10:00', 42);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (145, 'ENTRADA', 3, '2026-03-08 11:10:00', 55),
    (146, 'ENTRADA', 2, '2026-03-09 18:45:00', 35),
    (147, 'ENTRADA', 5, '2026-03-11 14:30:00', 5),
    (148, 'ENTRADA', 9, '2026-03-13 09:40:00', 30),
    (149, 'ENTRADA', 3, '2026-03-14 14:50:00', 59),
    (150, 'ENTRADA', 4, '2026-03-14 17:50:00', 6),
    (151, 'ENTRADA', 3, '2026-03-16 17:00:00', 57),
    (152, 'ENTRADA', 8, '2026-03-20 09:30:00', 39),
    (153, 'ENTRADA', 3, '2026-03-21 12:00:00', 49),
    (154, 'ENTRADA', 2, '2026-03-21 17:10:00', 14),
    (155, 'SAIDA', 5, '2026-03-22 11:45:00', 12),
    (156, 'SAIDA', 4, '2026-03-22 12:45:00', 16);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (157, 'ENTRADA', 2, '2026-03-22 15:20:00', 46),
    (158, 'SAIDA', 2, '2026-03-22 22:45:00', 29),
    (159, 'SAIDA', 2, '2026-03-23 01:45:00', 45),
    (160, 'ENTRADA', 1, '2026-03-23 08:45:00', 15),
    (161, 'ENTRADA', 3, '2026-03-23 17:40:00', 34),
    (162, 'ENTRADA', 3, '2026-03-24 10:40:00', 22),
    (163, 'SAIDA', 2, '2026-03-24 11:40:00', 17),
    (164, 'SAIDA', 6, '2026-03-24 14:40:00', 32),
    (165, 'SAIDA', 10, '2026-03-24 18:40:00', 16),
    (166, 'SAIDA', 1, '2026-03-26 16:20:00', 38),
    (167, 'SAIDA', 4, '2026-03-26 17:20:00', 57),
    (168, 'SAIDA', 1, '2026-03-26 23:20:00', 10);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (169, 'SAIDA', 4, '2026-03-26 23:20:00', 18),
    (170, 'SAIDA', 1, '2026-03-27 07:20:00', 26),
    (171, 'ENTRADA', 6, '2026-03-28 15:40:00', 25),
    (172, 'ENTRADA', 10, '2026-04-02 04:40:00', 50),
    (173, 'SAIDA', 10, '2026-04-03 04:40:00', 50),
    (174, 'SAIDA', 3, '2026-04-03 05:40:00', 48),
    (175, 'SAIDA', 3, '2026-04-03 13:20:00', 13),
    (176, 'SAIDA', 5, '2026-04-03 15:20:00', 14),
    (177, 'SAIDA', 12, '2026-04-03 16:15:00', 40),
    (178, 'SAIDA', 1, '2026-04-03 18:40:00', 45),
    (179, 'SAIDA', 5, '2026-04-03 20:15:00', 60),
    (180, 'SAIDA', 10, '2026-04-03 23:15:00', 35);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (181, 'SAIDA', 2, '2026-04-04 00:40:00', 53),
    (182, 'SAIDA', 3, '2026-04-04 02:40:00', 10),
    (183, 'SAIDA', 2, '2026-04-04 04:20:00', 56),
    (184, 'ENTRADA', 3, '2026-04-04 15:15:00', 32),
    (185, 'SAIDA', 12, '2026-04-04 18:50:00', 30),
    (186, 'SAIDA', 5, '2026-04-05 03:50:00', 56),
    (187, 'SAIDA', 1, '2026-04-07 18:50:00', 44),
    (188, 'SAIDA', 1, '2026-04-08 07:50:00', 41),
    (189, 'SAIDA', 2, '2026-04-12 17:00:00', 56),
    (190, 'SAIDA', 2, '2026-04-12 18:00:00', 18),
    (191, 'SAIDA', 2, '2026-04-12 18:15:00', 6),
    (192, 'SAIDA', 3, '2026-04-12 21:15:00', 21);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (193, 'SAIDA', 1, '2026-04-12 23:15:00', 14),
    (194, 'SAIDA', 4, '2026-04-13 01:15:00', 32),
    (195, 'SAIDA', 12, '2026-04-13 02:15:00', 60),
    (196, 'SAIDA', 5, '2026-04-13 03:15:00', 50),
    (197, 'SAIDA', 6, '2026-04-13 04:15:00', 48),
    (198, 'ENTRADA', 4, '2026-04-19 17:15:00', 50),
    (199, 'SAIDA', 2, '2026-04-23 20:20:00', 5),
    (200, 'SAIDA', 2, '2026-04-24 09:20:00', 7),
    (201, 'SAIDA', 3, '2026-04-24 10:20:00', 32),
    (202, 'ENTRADA', 10, '2026-04-30 19:45:00', 14),
    (203, 'ENTRADA', 3, '2026-05-01 16:10:00', 57),
    (204, 'ENTRADA', 2, '2026-05-01 18:50:00', 35);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (205, 'SAIDA', 5, '2026-05-01 19:45:00', 14),
    (206, 'SAIDA', 1, '2026-05-01 23:40:00', 44),
    (207, 'SAIDA', 12, '2026-05-02 01:45:00', 12),
    (208, 'SAIDA', 6, '2026-05-02 02:40:00', 34),
    (209, 'SAIDA', 4, '2026-05-02 06:45:00', 7),
    (210, 'ENTRADA', 3, '2026-05-03 09:15:00', 55),
    (211, 'ENTRADA', 1, '2026-05-03 12:30:00', 15),
    (212, 'ENTRADA', 2, '2026-05-03 15:00:00', 37),
    (213, 'SAIDA', 6, '2026-05-05 15:50:00', 22),
    (214, 'SAIDA', 1, '2026-05-05 16:50:00', 49),
    (215, 'ENTRADA', 3, '2026-05-06 12:20:00', 29),
    (216, 'ENTRADA', 9, '2026-05-07 11:20:00', 28);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (217, 'ENTRADA', 7, '2026-05-07 11:30:00', 36),
    (218, 'ENTRADA', 3, '2026-05-08 08:40:00', 51),
    (219, 'ENTRADA', 9, '2026-05-08 13:10:00', 27),
    (220, 'ENTRADA', 1, '2026-05-11 09:00:00', 38),
    (221, 'ENTRADA', 4, '2026-05-11 16:50:00', 6),
    (222, 'ENTRADA', 4, '2026-05-13 11:10:00', 7),
    (223, 'ENTRADA', 10, '2026-05-13 11:30:00', 44),
    (224, 'SAIDA', 2, '2026-05-13 11:40:00', 30),
    (225, 'ENTRADA', 4, '2026-05-13 12:15:00', 18),
    (226, 'ENTRADA', 9, '2026-05-13 16:40:00', 56),
    (227, 'ENTRADA', 13, '2026-05-14 05:15:00', 57),
    (228, 'SAIDA', 12, '2026-05-14 12:15:00', 18);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (229, 'ENTRADA', 3, '2026-05-14 13:45:00', 32),
    (230, 'SAIDA', 2, '2026-05-14 15:15:00', 25),
    (231, 'SAIDA', 2, '2026-05-15 04:15:00', 28),
    (232, 'SAIDA', 5, '2026-05-15 05:15:00', 57),
    (233, 'ENTRADA', 3, '2026-05-16 11:10:00', 22),
    (234, 'SAIDA', 1, '2026-05-16 13:40:00', 6),
    (235, 'SAIDA', 12, '2026-05-16 20:40:00', 28),
    (236, 'ENTRADA', 14, '2026-05-18 16:20:00', 48),
    (237, 'SAIDA', 5, '2026-05-20 12:15:00', 34),
    (238, 'SAIDA', 10, '2026-05-20 15:15:00', 60),
    (239, 'ENTRADA', 2, '2026-05-20 15:20:00', 14),
    (240, 'SAIDA', 10, '2026-05-20 18:15:00', 29);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (241, 'SAIDA', 10, '2026-05-21 00:15:00', 44),
    (242, 'SAIDA', 12, '2026-05-21 03:15:00', 25),
    (243, 'ENTRADA', 6, '2026-05-21 10:20:00', 25),
    (244, 'ENTRADA', 1, '2026-05-21 11:45:00', 41),
    (245, 'ENTRADA', 7, '2026-05-24 15:00:00', 53),
    (246, 'ENTRADA', 11, '2026-05-24 16:40:00', 16),
    (247, 'ENTRADA', 4, '2026-05-25 12:10:00', 43),
    (248, 'ENTRADA', 20, '2026-05-25 17:40:00', 60),
    (249, 'ENTRADA', 4, '2026-05-25 17:45:00', 50),
    (250, 'ENTRADA', 20, '2026-05-26 02:45:00', 34),
    (251, 'ENTRADA', 3, '2026-05-26 09:15:00', 49),
    (252, 'SAIDA', 4, '2026-05-27 02:45:00', 34);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (253, 'SAIDA', 6, '2026-05-27 03:45:00', 5),
    (254, 'SAIDA', 4, '2026-05-27 23:20:00', 43),
    (255, 'SAIDA', 6, '2026-05-27 23:20:00', 51),
    (256, 'SAIDA', 2, '2026-05-28 01:20:00', 53),
    (257, 'ENTRADA', 3, '2026-05-28 13:20:00', 52),
    (258, 'ENTRADA', 9, '2026-06-01 12:30:00', 30),
    (259, 'ENTRADA', 3, '2026-06-02 17:20:00', 21),
    (260, 'ENTRADA', 5, '2026-06-03 11:10:00', 5),
    (261, 'ENTRADA', 5, '2026-06-07 11:40:00', 34),
    (262, 'ENTRADA', 1, '2026-06-07 11:50:00', 42),
    (263, 'SAIDA', 6, '2026-06-08 19:45:00', 60),
    (264, 'SAIDA', 2, '2026-06-09 08:45:00', 42);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (265, 'ENTRADA', 5, '2026-06-10 12:40:00', 40),
    (266, 'SAIDA', 5, '2026-06-10 18:45:00', 31),
    (267, 'SAIDA', 2, '2026-06-10 18:45:00', 40),
    (268, 'SAIDA', 2, '2026-06-11 06:45:00', 56),
    (269, 'ENTRADA', 1, '2026-06-11 11:40:00', 1),
    (270, 'ENTRADA', 1, '2026-06-11 16:45:00', 8),
    (271, 'SAIDA', 1, '2026-06-15 18:40:00', 41),
    (272, 'SAIDA', 12, '2026-06-16 00:40:00', 52),
    (273, 'SAIDA', 2, '2026-06-16 08:40:00', 55),
    (274, 'ENTRADA', 8, '2026-06-16 09:10:00', 18),
    (275, 'ENTRADA', 5, '2026-06-18 16:45:00', 9),
    (276, 'SAIDA', 5, '2026-06-19 13:40:00', 21);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (277, 'SAIDA', 4, '2026-06-19 21:40:00', 19),
    (278, 'ENTRADA', 8, '2026-06-20 13:45:00', 39),
    (279, 'ENTRADA', 2, '2026-06-22 18:40:00', 54),
    (280, 'SAIDA', 2, '2026-06-23 17:15:00', 49),
    (281, 'ENTRADA', 2, '2026-06-23 17:50:00', 11),
    (282, 'SAIDA', 2, '2026-06-23 18:15:00', 39),
    (283, 'SAIDA', 2, '2026-06-24 04:15:00', 17),
    (284, 'ENTRADA', 2, '2026-06-24 13:00:00', 46),
    (285, 'ENTRADA', 1, '2026-06-24 13:15:00', 19),
    (286, 'ENTRADA', 3, '2026-06-28 05:10:00', 51),
    (287, 'ENTRADA', 3, '2026-06-28 09:50:00', 59),
    (288, 'SAIDA', 4, '2026-06-28 20:10:00', 27);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (289, 'SAIDA', 4, '2026-06-29 00:10:00', 22),
    (290, 'SAIDA', 1, '2026-06-29 03:10:00', 48),
    (291, 'SAIDA', 12, '2026-06-29 05:10:00', 51),
    (292, 'ENTRADA', 3, '2026-07-01 11:10:00', 32),
    (293, 'ENTRADA', 7, '2026-07-03 15:15:00', 50),
    (294, 'ENTRADA', 1, '2026-07-04 10:00:00', 33),
    (295, 'ENTRADA', 5, '2026-07-05 11:20:00', 14),
    (296, 'SAIDA', 3, '2026-07-06 03:10:00', 13),
    (297, 'SAIDA', 4, '2026-07-06 04:10:00', 25),
    (298, 'SAIDA', 10, '2026-07-06 04:10:00', 28),
    (299, 'SAIDA', 5, '2026-07-06 09:40:00', 40),
    (300, 'SAIDA', 1, '2026-07-06 13:40:00', 2);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (301, 'ENTRADA', 1, '2026-07-09 15:15:00', 2),
    (302, 'ENTRADA', 2, '2026-07-10 08:50:00', 10),
    (303, 'ENTRADA', 3, '2026-07-11 13:00:00', 49),
    (304, 'SAIDA', 5, '2026-07-12 23:15:00', 33),
    (305, 'SAIDA', 6, '2026-07-13 05:15:00', 6),
    (306, 'SAIDA', 10, '2026-07-13 06:15:00', 59),
    (307, 'SAIDA', 12, '2026-07-13 11:15:00', 25),
    (308, 'ENTRADA', 7, '2026-07-17 15:45:00', 25),
    (309, 'ENTRADA', 2, '2026-07-18 15:50:00', 13),
    (310, 'ENTRADA', 4, '2026-07-19 08:40:00', 52),
    (311, 'ENTRADA', 6, '2026-07-19 14:20:00', 29),
    (312, 'ENTRADA', 4, '2026-07-20 16:40:00', 22);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (313, 'SAIDA', 3, '2026-07-21 12:30:00', 21),
    (314, 'SAIDA', 3, '2026-07-21 15:40:00', 32),
    (315, 'SAIDA', 5, '2026-07-21 22:30:00', 49),
    (316, 'SAIDA', 1, '2026-07-21 23:30:00', 1),
    (317, 'SAIDA', 12, '2026-07-21 23:40:00', 48),
    (318, 'SAIDA', 2, '2026-07-22 03:40:00', 52),
    (319, 'SAIDA', 2, '2026-07-22 10:30:00', 5),
    (320, 'SAIDA', 5, '2026-07-22 11:20:00', 25),
    (321, 'SAIDA', 3, '2026-07-22 14:20:00', 27),
    (322, 'ENTRADA', 2, '2026-07-22 15:10:00', 15),
    (323, 'ENTRADA', 2, '2026-07-22 16:15:00', 31),
    (324, 'SAIDA', 12, '2026-07-22 16:20:00', 9);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (325, 'ENTRADA', 2, '2026-07-22 18:00:00', 38),
    (326, 'SAIDA', 2, '2026-07-22 22:30:00', 36),
    (327, 'SAIDA', 6, '2026-07-23 00:30:00', 9),
    (328, 'SAIDA', 12, '2026-07-23 00:30:00', 16),
    (329, 'ENTRADA', 6, '2026-07-23 18:15:00', 57),
    (330, 'ENTRADA', 1, '2026-07-25 08:40:00', 35),
    (331, 'ENTRADA', 6, '2026-07-25 18:10:00', 51),
    (332, 'SAIDA', 2, '2026-07-26 02:40:00', 38),
    (333, 'SAIDA', 4, '2026-07-26 08:40:00', 35),
    (334, 'ENTRADA', 5, '2026-07-26 12:50:00', 55),
    (335, 'SAIDA', 1, '2026-07-27 09:00:00', 60),
    (336, 'SAIDA', 2, '2026-07-27 12:00:00', 10);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (337, 'ENTRADA', 4, '2026-07-27 13:30:00', 35),
    (338, 'ENTRADA', 6, '2026-07-28 11:40:00', 6),
    (339, 'SAIDA', 4, '2026-08-20 03:15:00', 46),
    (340, 'SAIDA', 12, '2026-08-20 13:15:00', 27),
    (341, 'SAIDA', 2, '2026-08-20 19:20:00', 27),
    (342, 'SAIDA', 12, '2026-08-20 19:20:00', 30),
    (343, 'SAIDA', 1, '2026-08-20 21:30:00', 35),
    (344, 'SAIDA', 6, '2026-08-20 23:10:00', 11),
    (345, 'SAIDA', 3, '2026-08-21 02:20:00', 15),
    (346, 'SAIDA', 10, '2026-08-21 03:10:00', 39),
    (347, 'SAIDA', 3, '2026-08-21 04:10:00', 41),
    (348, 'SAIDA', 2, '2026-08-21 05:20:00', 37);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (349, 'SAIDA', 12, '2026-08-21 13:20:00', 44),
    (350, 'SAIDA', 2, '2026-08-21 19:20:00', 29),
    (351, 'SAIDA', 10, '2026-08-22 00:20:00', 60),
    (352, 'SAIDA', 5, '2026-08-24 13:00:00', 32),
    (353, 'SAIDA', 4, '2026-08-24 20:00:00', 24),
    (354, 'SAIDA', 5, '2026-09-01 18:00:00', 29),
    (355, 'SAIDA', 4, '2026-09-01 19:00:00', 20),
    (356, 'SAIDA', 10, '2026-09-02 10:00:00', 55),
    (357, 'SAIDA', 1, '2026-09-05 15:00:00', 34),
    (358, 'SAIDA', 1, '2026-09-05 17:00:00', 6),
    (359, 'SAIDA', 3, '2026-09-05 17:00:00', 36),
    (360, 'SAIDA', 2, '2026-09-05 20:00:00', 22);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (361, 'SAIDA', 12, '2026-09-05 21:00:00', 60),
    (362, 'SAIDA', 2, '2026-09-05 22:00:00', 7),
    (363, 'SAIDA', 6, '2026-09-05 23:00:00', 46),
    (364, 'SAIDA', 3, '2026-09-06 04:00:00', 57),
    (365, 'SAIDA', 6, '2026-09-08 17:00:00', 55),
    (366, 'SAIDA', 3, '2026-09-08 20:00:00', 6),
    (367, 'SAIDA', 5, '2026-09-08 22:00:00', 43),
    (368, 'SAIDA', 12, '2026-09-09 01:00:00', 39),
    (369, 'SAIDA', 3, '2026-09-09 10:40:00', 43),
    (370, 'SAIDA', 5, '2026-09-09 12:00:00', 37),
    (371, 'SAIDA', 1, '2026-09-12 22:40:00', 8),
    (372, 'SAIDA', 12, '2026-09-12 23:15:00', 56);

INSERT INTO movimentacao_estoque
    (idmovimentacao_estoque, tipo, quantidade, data_hora, estoque_idestoque)
VALUES
    (373, 'SAIDA', 2, '2026-09-13 01:40:00', 48),
    (374, 'SAIDA', 5, '2026-09-13 03:15:00', 39);

-- =========================================================
-- AUTO_INCREMENT
-- Os ids foram informados na mão para as chaves estrangeiras
-- ficarem previsíveis. Isto reposiciona os contadores para que
-- novos registros não colidam com a carga.
-- =========================================================
ALTER TABLE pessoa                 AUTO_INCREMENT = 106;
ALTER TABLE categoria              AUTO_INCREMENT = 41;
ALTER TABLE fornecedor             AUTO_INCREMENT = 41;
ALTER TABLE produto                AUTO_INCREMENT = 61;
ALTER TABLE pedido                 AUTO_INCREMENT = 71;
ALTER TABLE pagamento              AUTO_INCREMENT = 71;
ALTER TABLE entrega                AUTO_INCREMENT = 43;
ALTER TABLE estoque                AUTO_INCREMENT = 61;
ALTER TABLE movimentacao_estoque   AUTO_INCREMENT = 375;

-- Conferência rápida do volume carregado.
SELECT 'pessoa' AS tabela, COUNT(*) AS linhas FROM pessoa
UNION ALL SELECT 'cliente', COUNT(*) FROM cliente
UNION ALL SELECT 'funcionario', COUNT(*) FROM funcionario
UNION ALL SELECT 'categoria', COUNT(*) FROM categoria
UNION ALL SELECT 'fornecedor', COUNT(*) FROM fornecedor
UNION ALL SELECT 'produto', COUNT(*) FROM produto
UNION ALL SELECT 'produto_fornecedor', COUNT(*) FROM produto_fornecedor
UNION ALL SELECT 'pedido', COUNT(*) FROM pedido
UNION ALL SELECT 'item_pedido', COUNT(*) FROM item_pedido
UNION ALL SELECT 'pagamento', COUNT(*) FROM pagamento
UNION ALL SELECT 'entrega', COUNT(*) FROM entrega
UNION ALL SELECT 'estoque', COUNT(*) FROM estoque
UNION ALL SELECT 'movimentacao_estoque', COUNT(*) FROM movimentacao_estoque
ORDER BY linhas DESC;
