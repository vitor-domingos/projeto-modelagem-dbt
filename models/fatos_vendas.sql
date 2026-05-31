{{ config(materialized='table') }}

WITH staging_vendas AS (
    SELECT 
        id_pedido,
        id_cliente,
        id_produto,
        quantidade,
        PARSE_DATE('%Y-%m-%d', data_compra) AS data_compra
    FROM {{ source('loja_raw', 'raw_vendas') }}
),

clientes AS (
    SELECT sk_cliente, id_cliente FROM {{ ref('dim_clientes') }}
),

produtos AS (
    SELECT sk_produto, id_produto, preco_unitario FROM {{ ref('dim_produtos') }}
)

SELECT 
    v.id_pedido,
    c.sk_cliente,
    p.sk_produto,
    v.quantidade,
    (v.quantidade * p.preco_unitario) AS valor_total_venda,
    v.data_compra
FROM staging_vendas v
INNER JOIN clientes c ON v.id_cliente = c.id_cliente
INNER JOIN produtos p ON v.id_produto = p.id_produto