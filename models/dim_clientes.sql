{{ config(materialized='table') }}

WITH staging_clientes AS (
    SELECT 
        id_cliente,
        UPPER(nome) AS nome_cliente,
        estado AS uf_cliente
    FROM {{ source('loja_raw', 'raw_clientes') }}
)

SELECT 
    -- Geração de chave substituta (Surrogate Key) para a dimensão
    GENERATE_UUID() AS sk_cliente,
    id_cliente,
    nome_cliente,
    uf_cliente
FROM staging_clientes