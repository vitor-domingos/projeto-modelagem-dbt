# Modelagem Dimensional (Star Schema) de E-commerce com dbt Cloud e Google BigQuery

Este repositório apresenta a implementação de um projeto prático de engenharia e modelagem de dados analíticos utilizando o **dbt Cloud (Data Build Tool)** integrado ao **Google BigQuery**. 

O objetivo do projeto é demonstrar a transformação de dados estruturados em formato bruto (*raw data*) de uma loja de varejo em um modelo dimensional otimizado para consultas analíticas baseado na arquitetura **Star Schema** (Tabelas Fato e Dimensões).

---

## Fluxo da Arquitetura Dimensional

O pipeline de dados opera sob o conceito de transformações in-database (T do processo ELT), estruturando os dados da seguinte forma:

```text
       [loja_raw.raw_vendas] (Fonte Bruta)
                 │
                 ├───► [loja_raw_dbt.fato_vendas] (Tabela Fato)
                 │            │             │
                 │            │             └─► [loja_raw_dbt.dim_produtos] (Dimensão)
                 │            │
                 │            └───────────────► [loja_raw_dbt.dim_clientes] (Dimensão)
                 │
  [loja_raw.raw_clientes] ── (Fonte Bruta)
  [loja_raw.raw_produtos] ── (Fonte Bruta)

Conceitos de Engenharia de Dados Aplicados

Modelagem Star Schema: Divisão de dados em entidades descritivas (Dimensões) e eventos quantificáveis (Fato), reduzindo a redundância e otimizando a performance de leitura.

Common Table Expressions (CTEs): Organização e limpeza de consultas SQL em etapas lógicas, legíveis e modulares.

Geração de Surrogate Keys (Chaves Substitutas): Utilização da função GENERATE_UUID() para criar chaves primárias internas nas tabelas de dimensão, isolando o ambiente analítico do operacional.

Independência de Ambiente: Configuração de arquivos de fontes (sources.yml) para mapear as tabelas de origem de maneira dinâmica.

Estrutura de Diretórios do dbt

O projeto está organizado dentro do repositório seguindo a estrutura padrão de desenvolvimento do dbt:

projeto-modelagem-dbt/
  ├── models/
  │     ├── sources.yml          # Declaração das fontes de dados brutas
  │     ├── dim_clientes.sql     # Modelo da dimensão de clientes
  │     ├── dim_produtos.sql     # Modelo da dimensão de produtos
  │     └── fato_vendas.sql      # Modelo da tabela fato de vendas
  └── dbt_project.yml            # Configurações globais do projeto dbt

Modelos SQL de Transformação

1. Declaração das Fontes (models/sources.yml)

Mapeamento lógico das tabelas brutas geradas no banco de dados para que o dbt possa referenciá-las dinamicamente.

version: 2

sources:
  - name: loja_raw
    database: summer-reducer-456821-p3 # Substitua pelo ID do seu projeto no GCP
    schema: loja_raw
    tables:
      - name: raw_clientes
      - name: raw_produtos
      - name: raw_vendas

2. Dimensão Clientes (models/dim_clientes.sql)

Tratamento das informações de cadastro dos clientes, com aplicação de padronizações textuais e criação de Surrogate Key.

{{ config(materialized='table') }}

WITH staging_clientes AS (
    SELECT 
        id_cliente,
        UPPER(nome) AS nome_cliente,
        estado AS uf_cliente
    FROM {{ source('loja_raw', 'raw_clientes') }}
)

SELECT 
    GENERATE_UUID() AS sk_cliente,
    id_cliente,
    nome_cliente,
    uf_cliente
FROM staging_clientes

3. Dimensão Produtos (models/dim_produtos.sql)

Tratamento e limpeza de dados mercadológicos dos produtos oferecidos no e-commerce.

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

4. Tabela Fato Vendas (models/fato_vendas.sql)

Consolidação dos fatos transacionais (vendas), gerando métricas financeiras derivadas (valor total) e mapeando o relacionamento com as chaves substitutas das dimensões.

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

Como Executar o Projeto

1. Com o ambiente do dbt Cloud configurado e conectado ao BigQuery, abra a barra de console inferior (Command Line).

2. Execute o comando para compilar e criar as tabelas no seu banco de dados:

dbt run

3. Verifique o log de execução no console para validar se os três modelos foram gerados com sucesso.

4. Acesse o painel do Google BigQuery para consultar as tabelas estruturadas criadas sob o esquema analítico gerado pelo dbt.

Licença

Este projeto está sob a licença MIT. Sinta-se livre para utilizá-lo, modificá-lo e distribuí-lo.
