{{ config(materialized='table') }}

WITH staging_produtos AS (
    SELECT 
        id_produto,
        UPPER(descricao) AS nome_produto,
        categoria AS categoria_produto,
        preco AS preco_unitario
    FROM {{ source('loja_raw', 'raw_produtos') }}
)

SELECT 
    GENERATE_UUID() AS sk_produto,
    id_produto,
    nome_produto,
    categoria_produto,
    preco_unitario
FROM staging_produtos