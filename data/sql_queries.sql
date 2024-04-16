-- Imobiliária Terra Bela 
-- Volume de Vendas
-- 1. Qual o volume geral de vendas da imobiliária no período avaliado?
SELECT 
	SUM(preco_venda) AS volume_geral_vendas
FROM imob.db_transacoes
ORDER BY volume_geral_vendas;

-- 2. Quantos imóveis foram vendidos no mesmo período?
SELECT 
	COUNT(id_transacao) AS imoveis_vendidos
FROM imob.db_transacoes
ORDER BY imoveis_vendidos;

-- 3. Quantos imóveis foram vendidos por tipo?
SELECT 
	imo.tipo_imovel,
	COUNT(tra.id_transacao) AS total_vendidos
FROM imob.db_imoveis as imo
LEFT JOIN imob.db_transacoes as tra
	ON imo.id_imovel = tra.id_imovel
GROUP BY imo.tipo_imovel
ORDER BY total_vendidos DESC

-- 4. Quantos imóveis foram vendidos por estado de conservação?
SELECT 
	imo.estado_conservacao,
	COUNT(tra.id_transacao) AS total_vendidos
FROM imob.db_imoveis as imo
LEFT JOIN imob.db_transacoes as tra
	ON imo.id_imovel = tra.id_imovel
GROUP BY imo.estado_conservacao
ORDER BY total_vendidos DESC

-- 5. Qual o volume de vendas em cada Estado?

CREATE TEMP TABLE novo_endereco AS
SELECT 
	id_imovel,
	TRIM(SPLIT_PART(endereco, ',', 1)) AS rua,
	TRIM(SPLIT_PART(endereco, ',', 2)) AS num_casa,
	TRIM(SPLIT_PART(endereco, ',', 3)) AS cidade,
	TRIM(SPLIT_PART(endereco, ',', 4)) AS estado	
FROM imob.db_imoveis

UPDATE novo_endereco
SET estado = 'São Paulo'
WHERE cidade = 'São Paulo'

UPDATE novo_endereco
SET estado = 'Rio de Janeiro'
WHERE cidade = 'Rio de Janeiro'

UPDATE novo_endereco
SET estado = 'Minas Gerais'
WHERE cidade = 'Minas Gerais'

UPDATE novo_endereco
SET estado = 'Espírito Santo'
WHERE cidade = 'Espírito Santo'


SELECT
	novo_endereco.estado,
	COUNT(tra.id_transacao) AS total_vendas
FROM imob.db_transacoes AS tra
LEFT JOIN novo_endereco
	ON novo_endereco.id_imovel = tra.id_imovel
GROUP BY novo_endereco.estado
ORDER BY total_vendas DESC;

-- 6. Qual o volume geral de vendas mês a mês no período?

SELECT
	DATE_TRUNC('month', data_transacao)::date AS mes,
	COUNT(id_transacao) AS total_vendas,
	SUM(preco_venda) AS volume_geral_vendas
FROM imob.db_transacoes
GROUP BY mes
ORDER BY mes 

-- Perfil dos clientes
-- 1. Qual a renda média dos clientes por Estado
CREATE TEMP TABLE cliente_end AS
SELECT 
	id_cliente,
	TRIM(SPLIT_PART(endereco, ',', 1)) AS rua,
	TRIM(SPLIT_PART(endereco, ',', 2)) AS num_casa,
	TRIM(SPLIT_PART(endereco, ',', 3)) AS cidade,
	TRIM(SPLIT_PART(endereco, ',', 4)) AS estado	
FROM imob.db_clientes

UPDATE cliente_end
SET estado = 'São Paulo'
WHERE cidade = 'São Paulo'

UPDATE cliente_end
SET estado = 'Rio de Janeiro'
WHERE cidade = 'Rio de Janeiro'

UPDATE cliente_end
SET estado = 'Minas Gerais'
WHERE cidade = 'Minas Gerais'

UPDATE cliente_end
SET estado = 'Espírito Santo'
WHERE cidade = 'Espírito Santo'

SELECT
	cliente_end.estado,
	AVG(faixa_renda) AS media_renda
FROM cliente_end
LEFT JOIN imob.db_clientes AS cli
	ON cli.id_cliente = cliente_end.id_cliente
GROUP BY cliente_end.estado

-- 2. Segmente os clientes por classe
-- Imóveis vendidos em cada estado, agrupados por classe
CREATE TEMP TABLE classe_renda AS
SELECT 
	id_cliente,
	faixa_renda,
	CASE
		WHEN faixa_renda < 7600 THEN 'Classe C'
		WHEN faixa_renda < 28800 THEN 'Classe B'
		ELSE 'Classe A' END AS classe_renda
FROM imob.db_clientes

SELECT 
	cliente_end.estado,
	classe_renda.classe_renda,
	COUNT(tra.id_transacao) AS total_vendas
FROM imob.db_transacoes AS tra
LEFT JOIN cliente_end
	ON cliente_end.id_cliente = tra.id_cliente
LEFT JOIN classe_renda
	ON classe_renda.id_cliente = tra.id_cliente
GROUP BY cliente_end.estado, classe_renda.classe_renda
ORDER BY classe_renda.classe_renda

-- Imóveis vendidos por cada estado de conservação agrupados por classe de renda
SELECT
	classe_renda.classe_renda,
	imo.estado_conservacao,
	COUNT(tra.id_transacao) AS total_vendas
FROM imob.db_transacoes AS tra
LEFT JOIN classe_renda
	ON tra.id_cliente = classe_renda.id_cliente
LEFT JOIN imob.db_imoveis AS imo
	ON tra.id_imovel = imo.id_imovel
GROUP BY classe_renda.classe_renda, imo.estado_conservacao
ORDER BY imo.estado_conservacao

-- Imóveis por cada tipo agrupados por classe de renda
SELECT
	classe_renda.classe_renda,
	imo.tipo_imovel,
	COUNT(tra.id_transacao) AS total_vendas
FROM imob.db_transacoes AS tra
LEFT JOIN classe_renda
	ON tra.id_cliente = classe_renda.id_cliente
LEFT JOIN imob.db_imoveis AS imo
	ON tra.id_imovel = imo.id_imovel
GROUP BY classe_renda.classe_renda, imo.tipo_imovel
ORDER BY imo.tipo_imovel

-- Total de clientes por classe
SELECT 
	classe_renda,
	COUNT(id_cliente) AS total
FROM classe_renda
GROUP BY classe_renda
ORDER BY total DESC

-- Volume geral de vendas movimentado por cada classe
SELECT 
	DATE_TRUNC('month', data_transacao)::date AS mes,
	classe_renda.classe_renda,
	SUM(tra.preco_venda) AS volume_geral_vendas
FROM imob.db_transacoes AS tra
LEFT JOIN classe_renda
	ON tra.id_cliente = classe_renda.id_cliente
GROUP BY mes, classe_renda.classe_renda
ORDER BY mes

-- Desempenho dos corretores
-- 1. Quais corretores movimentaram mais volume de vendas em cada estado?
-- SÃO PAULO
SELECT
	age.nome,
	novo_endereco.estado,
	SUM(tra.preco_venda) AS volume_geral_vendas
FROM imob.db_transacoes AS tra
LEFT JOIN imob.db_agentes AS age
	ON tra.id_corretor = age.id_corretor
LEFT JOIN novo_endereco
	ON novo_endereco.id_imovel = tra.id_imovel
GROUP BY age.nome, novo_endereco.estado
HAVING estado = 'São Paulo'
ORDER BY volume_geral_vendas DESC

-- RIO DE JANEIRO
SELECT
	age.nome,
	novo_endereco.estado,
	SUM(tra.preco_venda) AS volume_geral_vendas
FROM imob.db_transacoes AS tra
LEFT JOIN imob.db_agentes AS age
	ON tra.id_corretor = age.id_corretor
LEFT JOIN novo_endereco
	ON novo_endereco.id_imovel = tra.id_imovel
GROUP BY age.nome, novo_endereco.estado
HAVING estado = 'Rio de Janeiro'
ORDER BY volume_geral_vendas DESC

-- MINAS GERAIS
SELECT
	age.nome,
	novo_endereco.estado,
	SUM(tra.preco_venda) AS volume_geral_vendas
FROM imob.db_transacoes AS tra
LEFT JOIN imob.db_agentes AS age
	ON tra.id_corretor = age.id_corretor
LEFT JOIN novo_endereco
	ON novo_endereco.id_imovel = tra.id_imovel
GROUP BY age.nome, novo_endereco.estado
HAVING estado = 'Minas Gerais'
ORDER BY volume_geral_vendas DESC

-- ESPÍRITO SANTO
SELECT
	age.nome,
	novo_endereco.estado,
	SUM(tra.preco_venda) AS volume_geral_vendas
FROM imob.db_transacoes AS tra
LEFT JOIN imob.db_agentes AS age
	ON tra.id_corretor = age.id_corretor
LEFT JOIN novo_endereco
	ON novo_endereco.id_imovel = tra.id_imovel
GROUP BY age.nome, novo_endereco.estado
HAVING estado = 'Espírito Santo'
ORDER BY volume_geral_vendas DESC

-- 2. Quais corretores venderam mais unidades? (Top 10)
SELECT
	age.nome,
	COUNT(tra.id_transacao) AS total
FROM imob.db_transacoes AS tra
LEFT JOIN imob.db_agentes AS age
	ON tra.id_corretor = age.id_corretor
GROUP BY age.nome
ORDER BY total DESC
LIMIT 10

-- 3. Quais corretores tiveram o maior volume de comissões? (Top 10)
SELECT
	age.nome,
	SUM(tra.comissao_corretor) AS total
FROM imob.db_transacoes AS tra
LEFT JOIN imob.db_agentes AS age
	ON tra.id_corretor = age.id_corretor
GROUP BY age.nome
ORDER BY total DESC
LIMIT 10

-- Removendo as tabelas temporárias
DROP TABLE novo_endereco
DROP TABLE cliente_end
DROP TABLE classe_renda