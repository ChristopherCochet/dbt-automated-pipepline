-- crypto_prices.sql
{{
    config(
        materialized = 'incremental',
        unique_key = 'event_date'
    )
}}

with global_crypto as (

    select * from {{ ref('stg_global_crypto') }}
    where true
    {% if is_incremental() %}

        and _inserted_at >= (
            select max(event_date) as most_recent_record from {{ this }}
        )

    {% endif %}
)
select 
    date_trunc('day',_inserted_at) as event_date,
    count(_inserted_at) as count_price_udpates,
    count(distinct symbol) as count_cryptos,
    avg(price_usd) as avg_crypto_prices
from global_crypto
group by 1
