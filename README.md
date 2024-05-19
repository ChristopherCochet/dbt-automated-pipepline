### Run Status

| Runs | Branch | Status |
| --- | --- | --- |
| **Transform pipeline** | main | [![dbt-tranform-CI](https://github.com/ChristopherCochet/dbt-example/actions/workflows/ci.yml/badge.svg)](https://github.com/ChristopherCochet/dbt-example/actions/workflows/ci.yml) |
**Ingestion script** | main | [![meltano-ingestion-CI](https://github.com/ChristopherCochet/dbt-example/actions/workflows/ingestion.yml/badge.svg)](https://github.com/ChristopherCochet/dbt-example/actions/workflows/ingestion.yml) |


# dbt core pipeline example overview
This repo showcases a dbt a simple **dbt core** pipeline paired with an data api ingestion script ran with **meltano** and schedule using **github actions**. The source tables and downstream tables are created in a **postgres database** hosted on [supabase](https://supabase.com/)


> [dbt core](https://www.getdbt.com/product/what-is-dbt) is an open-source tool that enables data practitioners to transform data and is suitable for users who prefer to manually set up dbt and locally maintain it

<p align="center" width="100%">
    <img src="images/dbt_core.png" width="180"/>
</p>

> [Supabase](https://supabase.com/) is a Backend-as-a-Service (BaaS) app development platform that provides hosted backend services such as a Postgres database, user authentication, file storage etc.

<p align="center" width="100%">
<img src="images/supabase.jpg" width="180"/>
</p>

> [Meltano](https://meltano.com/) is an open-source platform for orchestrating ELT pipelines, enabling data teams to fetch, send, and transform data effortlessly​. Meltano is an open-source platform designed for building, running, and orchestrating ELT pipelines, utilizing Singer taps, targets, and dbt models.

<p align="center" width="100%">
<img src="images/meltano.png" width="180"/>
</p>

# How This Pipeline Example Works

## Supabase - The Data Repository  

The pipeline runs on top a [Postgres SQL database](https://supabase.com/database) hosed in the cloud on Supabase. 
This postgres database hosts the tables used in the dbt core pipelines. Three schemas are defined:
- [`source`](models/staging/__sources.yml): store the source tables. Also where the ingestion of api data lands.
- [`staging`](models/staging/__models.yml): stores cleaned versions of the source tables using dbt
- [`marts`](models/marts/__models.yml): stores final aggregated report tables created by dbt

## Meltano - The Data Ingestion  

## API Data Extraction  
Meltano ingests data from an opensource API and write the data to the Supabase source tables. The [coinlore API](https://www.coinlore.com/cryptocurrency-data-api) is used to extract the data that holds daily crypto data and prices. The ingestion script is filtered on to the top 20 crypto coins data.

> Coinlore offers a public and free cryptocurrency API for developers and research projects and so on. Our API is open and doesn't require registration, providing reliable and independent data for over 12,000 crypto coins and more than 300 crypto exchanges.

<details>
    
```
Tickers (All coins)
Request Method: GET
Description: Get data for all coins. The maximum result is 100 coins per request. 
Request URL: https://api.coinlore.net/api/tickers/?start=20&limit=20
Response:
{
  "data": [
    {
      "id": "90",
      "symbol": "BTC",
      "name": "Bitcoin",
      "nameid": "bitcoin",
      "rank": 1,
      "price_usd": "6456.52",
      "percent_change_24h": "-1.47",
      "percent_change_1h": "0.05",
      "percent_change_7d": "-1.07",
      "price_btc": "1.00",
      "market_cap_usd": "111586042785.56",
      "volume24": 3997655362.9586277,
      "volume24a": 3657294860.710187,
      "csupply": "17282687.00",
      "tsupply": "17282687",
      "msupply": "21000000"
    },
  "info": {
    "coins_num": 1969,
    "time": 1538560355
  }
```

</details>

## Data Ingestion
Meltano writes the crypto API data to Supabase into a source table `global_crypto` when triggered.
The configuration of the extract and load meltano process can be found in the [`meltano.yml file`](meltano-ingestion/meltano.yml) with the relevant meltano settings below:

```
plugins:
  extractors:
  - name: tap-rest-api-msdk
    variant: widen
    pip_url: tap-rest-api-msdk
    capabilities:
    - state
    - catalog
    - discover    
    config:
      api_url: https://api.coinlore.net/api/tickers/?start=20&limit=20
      streams:
      - name: global_crypto
        primary_keys:
        - info_time
        records_path: $.[*]
  loaders:
  - name: target-postgres
    variant: meltanolabs
    pip_url: meltanolabs-target-postgres
    config:
      user: ${DB_USER}
      host: ${DB_HOST}
      # add_record_metadata: true
      database: ${DB_NAME}
      password: ${DB_PASS}
      port: 5432
      default_target_schema: sources
      load_method: append-only
```

## dbt core - The Data Transformation
A dbt core pipeline performs a series of transformation of the source tables - some are static tables but the crypto source table is updated frequently using github actions.

A couple of dbt models in the `marts` schema are **incremental models**, as an example the `crypto_prices` model

<details>

```
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

```
</details>


The transformations are performed in sql and from sources `schema tables -> staging schema tables -> marts schema tables`.

<details>

``` 
$ dbt list

# source tables
source:jaffle_shop.crypto.global_crypto
source:jaffle_shop.ecom.raw_customers
source:jaffle_shop.ecom.raw_items
source:jaffle_shop.ecom.raw_orders
source:jaffle_shop.ecom.raw_products
source:jaffle_shop.ecom.raw_stores
source:jaffle_shop.ecom.raw_supplies

# staging tables
jaffle_shop.staging.stg_customers
jaffle_shop.staging.stg_global_crypto
jaffle_shop.staging.stg_locations
jaffle_shop.staging.stg_order_items
jaffle_shop.staging.stg_orders
jaffle_shop.staging.stg_products
jaffle_shop.staging.stg_supplies

# marts tables
jaffle_shop.marts.crypto_prices
jaffle_shop.marts.customers
jaffle_shop.marts.orders
```

Building the entire pipeline and running dbt tests yields the following:

``` 
$ dbt build

02:38:41  Running with dbt=1.5.11
02:38:41  Registered adapter: postgres=1.5.11
02:38:41  Found 10 models, 20 tests, 0 snapshots, 0 analyses, 424 macros, 0 operations, 0 seed files, 7 sources, 0 exposures, 0 metrics, 0 groups
02:38:41  
02:38:42  Concurrency: 1 threads (target='dev')
02:38:42  
02:38:42  1 of 30 START sql view model staging.stg_customers ............................. [RUN]
02:38:42  1 of 30 OK created sql view model staging.stg_customers ........................ [CREATE VIEW in 0.17s]
02:38:42  2 of 30 START sql view model staging.stg_global_crypto ......................... [RUN]
02:38:42  2 of 30 OK created sql view model staging.stg_global_crypto .................... [CREATE VIEW in 0.12s]
02:38:42  3 of 30 START sql view model staging.stg_locations ............................. [RUN]
02:38:42  3 of 30 OK created sql view model staging.stg_locations ........................ [CREATE VIEW in 0.09s]
02:38:42  4 of 30 START sql view model staging.stg_order_items ........................... [RUN]
02:38:42  4 of 30 OK created sql view model staging.stg_order_items ...................... [CREATE VIEW in 0.10s]
02:38:42  5 of 30 START sql view model staging.stg_orders ................................ [RUN]
02:38:42  5 of 30 OK created sql view model staging.stg_orders ........................... [CREATE VIEW in 0.12s]
02:38:42  6 of 30 START sql view model staging.stg_products .............................. [RUN]
02:38:42  6 of 30 OK created sql view model staging.stg_products ......................... [CREATE VIEW in 0.10s]
02:38:42  7 of 30 START sql view model staging.stg_supplies .............................. [RUN]
02:38:42  7 of 30 OK created sql view model staging.stg_supplies ......................... [CREATE VIEW in 0.13s]
02:38:42  8 of 30 START test not_null_stg_customers_customer_id .......................... [RUN]
02:38:43  8 of 30 PASS not_null_stg_customers_customer_id ................................ [PASS in 0.11s]
02:38:43  9 of 30 START test unique_stg_customers_customer_id ............................ [RUN]
02:38:43  9 of 30 PASS unique_stg_customers_customer_id .................................. [PASS in 0.05s]
02:38:43  10 of 30 START sql incremental model marts.crypto_prices ....................... [RUN]
02:38:43  10 of 30 OK created sql incremental model marts.crypto_prices .................. [INSERT 0 20 in 0.17s]
02:38:43  11 of 30 START test not_null_stg_locations_location_id ......................... [RUN]
02:38:43  11 of 30 PASS not_null_stg_locations_location_id ............................... [PASS in 0.05s]
02:38:43  12 of 30 START test unique_stg_locations_location_id ........................... [RUN]
02:38:43  12 of 30 PASS unique_stg_locations_location_id ................................. [PASS in 0.06s]
02:38:43  13 of 30 START test not_null_stg_order_items_order_item_id ..................... [RUN]
02:38:43  13 of 30 PASS not_null_stg_order_items_order_item_id ........................... [PASS in 0.11s]
02:38:43  14 of 30 START test unique_stg_order_items_order_item_id ....................... [RUN]
02:38:43  14 of 30 PASS unique_stg_order_items_order_item_id ............................. [PASS in 0.14s]
02:38:43  15 of 30 START test not_null_stg_orders_order_id ............................... [RUN]
02:38:43  15 of 30 PASS not_null_stg_orders_order_id ..................................... [PASS in 0.08s]
02:38:43  16 of 30 START test unique_stg_orders_order_id ................................. [RUN]
02:38:43  16 of 30 PASS unique_stg_orders_order_id ....................................... [PASS in 0.14s]
02:38:43  17 of 30 START test not_null_stg_products_product_id ........................... [RUN]
02:38:43  17 of 30 PASS not_null_stg_products_product_id ................................. [PASS in 0.09s]
02:38:43  18 of 30 START test unique_stg_products_product_id ............................. [RUN]
02:38:43  18 of 30 PASS unique_stg_products_product_id ................................... [PASS in 0.05s]
02:38:43  19 of 30 START test not_null_stg_supplies_supply_uuid .......................... [RUN]
02:38:44  19 of 30 PASS not_null_stg_supplies_supply_uuid ................................ [PASS in 0.06s]
02:38:44  20 of 30 START test unique_stg_supplies_supply_uuid ............................ [RUN]
02:38:44  20 of 30 PASS unique_stg_supplies_supply_uuid .................................. [PASS in 0.07s]
02:38:44  21 of 30 START sql incremental model marts.orders .............................. [RUN]
02:38:44  21 of 30 OK created sql incremental model marts.orders ......................... [INSERT 0 1 in 0.73s]
02:38:44  22 of 30 START test dbt_utils_expression_is_true_orders_count_food_items_count_drink_items_count_items  [RUN]
02:38:44  22 of 30 PASS dbt_utils_expression_is_true_orders_count_food_items_count_drink_items_count_items  [PASS in 0.12s]
02:38:44  23 of 30 START test dbt_utils_expression_is_true_orders_subtotal_food_items_subtotal_drink_items_subtotal  [RUN]
02:38:45  23 of 30 PASS dbt_utils_expression_is_true_orders_subtotal_food_items_subtotal_drink_items_subtotal  [PASS in 0.08s]
02:38:45  24 of 30 START test not_null_orders_order_id ................................... [RUN]
02:38:45  24 of 30 PASS not_null_orders_order_id ......................................... [PASS in 0.09s]
02:38:45  25 of 30 START test relationships_orders_customer_id__customer_id__ref_stg_customers_  [RUN]
02:38:45  25 of 30 PASS relationships_orders_customer_id__customer_id__ref_stg_customers_  [PASS in 0.08s]
02:38:45  26 of 30 START test unique_orders_order_id ..................................... [RUN]
02:38:45  26 of 30 PASS unique_orders_order_id ........................................... [PASS in 0.13s]
02:38:45  27 of 30 START sql table model marts.customers ................................. [RUN]
02:38:45  27 of 30 OK created sql table model marts.customers ............................ [SELECT 935 in 0.22s]
02:38:45  28 of 30 START test accepted_values_customers_customer_type__new__returning .... [RUN]
02:38:45  28 of 30 PASS accepted_values_customers_customer_type__new__returning .......... [PASS in 0.08s]
02:38:45  29 of 30 START test not_null_customers_customer_id ............................. [RUN]
02:38:45  29 of 30 PASS not_null_customers_customer_id ................................... [PASS in 0.06s]
02:38:45  30 of 30 START test unique_customers_customer_id ............................... [RUN]
02:38:45  30 of 30 PASS unique_customers_customer_id ..................................... [PASS in 0.07s]
02:38:45  
02:38:45  Finished running 7 view models, 20 tests, 2 incremental models, 1 table model in 0 hours 0 minutes and 4.38 seconds (4.38s).
02:38:45  
02:38:45  Completed successfully
02:38:45  
02:38:45  Done. PASS=30 WARN=0 ERROR=0 SKIP=0 TOTAL=30
```

</details>

## The Data Pipeline
The dbt pipeline is ran periodcially using github action and can then visualise the pipeline in the dbt core UI using the following commands:
- `dbt docs generate` and then 
- `dbt docs serve`

![](./images/dbt_pipeline.png?raw=true)

## Resources
-  [Supabase](https://supabase.com/)
-  [dbt Core](https://docs.getdbt.com/docs/introduction#:~:text=dbt%20Core%20is%20an%20open,the%20quickstart%20for%20dbt%20Core.)
- [ dbt-focused Jaffle Shop project](https://jaffle.sh/)
