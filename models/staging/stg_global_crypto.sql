-- stg_global_crypto.sql
with json_cte as (
	select
		info_time,
		info_coins_num,
		data::json as json_data
	from {{ source('crypto', 'global_crypto') }}
),
flatten_json as (
	select 
		info_time,
		info_coins_num,
		json_array_elements(json_data)->>'id' as id,
		json_array_elements(json_data)->>'symbol' as symbol,
		json_array_elements(json_data)->>'name' as name,
		json_array_elements(json_data)->>'nameid' as nameid,
		json_array_elements(json_data)->>'rank' as rank,
		json_array_elements(json_data)->>'price_usd' as price_usd,
		json_array_elements(json_data)->>'percent_change_24h' as percent_change_24h,
		json_array_elements(json_data)->>'percent_change_1h' as percent_change_1h,
		json_array_elements(json_data)->>'percent_change_7d' as percent_change_7d,
		json_array_elements(json_data)->>'price_btc' as price_btc,
		json_array_elements(json_data)->>'market_cap_usd' as market_cap_usd,
		json_array_elements(json_data)->>'volume24' as volume24,
		json_array_elements(json_data)->>'volume24a' as volume24a,
		json_array_elements(json_data)->>'csupply' as csupply,
		json_array_elements(json_data)->>'tsupply' as tsupply,
		json_array_elements(json_data)->>'msupply' as msupply
		from json_cte
	)
select
	to_timestamp(info_time) as ts,
	info_coins_num as num_coins,
    id,
    symbol,
    "name",
    nameid,
    "rank"::int,	
    nullif(price_usd, '')::float as price_usd,
    nullif(percent_change_24h, '')::float as percent_change_24h,
    nullif(percent_change_1h, '')::float as percent_change_1h,
    nullif(percent_change_7d, '')::float as percent_change_7d,
    nullif(price_btc, '')::float as price_btc,
    nullif(market_cap_usd, '')::float as market_cap_usd,
    nullif(volume24, '')::float as volume24,
    nullif(volume24a, '')::float as volume24a,
    nullif(csupply, '')::float as csupply,
    nullif(tsupply, '')::float as tsupply,
    nullif(msupply, '')::float as msupply
from flatten_json