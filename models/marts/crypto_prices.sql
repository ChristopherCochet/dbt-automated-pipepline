-- crypto_prices.sql
{{
    config(
        materialized = 'incremental',
        unique_key = 'event_date'
    )
}}

with global_crypto as (

    select * 
    from {{ ref('stg_global_crypto') }}
    where true
    {% if is_incremental() %}
        and ts >= (
            select max(event_date) as most_recent_record from {{ this }}
        )
    {% endif %}
)
select 
    date_trunc('day', ts) as event_date,
    symbol,
    "name",
    count(distinct ts) as count_table_udpates,
    count(distinct symbol) as count_cryptos,
    avg(price_usd) as avg_crypto_prices
from global_crypto
group by 1, 2, 3
