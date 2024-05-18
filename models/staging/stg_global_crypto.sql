-- stg_global_crypto.sql
select 
    id,
    symbol,
    "name",
    nameid,
    "rank"::int,	
    price_usd::float,
    percent_change_24h::float,
    percent_change_1h::float,
    percent_change_7d::float,
    price_btc::float,
    market_cap_usd::float,
    volume24::float,
    volume24a::float,
    csupply::int,
    tsupply::int,
    msupply::int,
    "_sdc_extracted_at"::timestamp as _inserted_at
from {{ source('crypto', 'global_crypto') }}
