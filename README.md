### Run Status

The nightly build tests are run daily on AzureML.

| Runs | Branch | Status |
| --- | --- | --- |
| **transform** | main | [![dbt Tranform CI](https://github.com/ChristopherCochet/dbt-example/actions/workflows/ci.yml/badge.svg)](https://github.com/ChristopherCochet/dbt-example/actions/workflows/ci.yml) | 
**ingestion** | main | [![Meltano Ingestion CI](https://github.com/ChristopherCochet/dbt-example/actions/workflows/ingestion.yml/badge.svg)](https://github.com/ChristopherCochet/dbt-example/actions/workflows/ingestion.yml)


# DBT Example
This repo is a simple DBT pipeline that uses a 'Jaffle Shop Project' to showcase dbt Core. The source tables and downstream tables are created in a postgres database hosted on [supabase](https://supabase.com/)

> dbt Core is an open-source tool that enables data practitioners to transform data and is suitable for users who prefer to manually set up dbt and locally maintain it>

> Supabase is a Backend-as-a-Service (BaaS) app development platform that provides hosted backend services such as a Postgres database, user authentication, file storage etc.

It runs once a week on Sundays using github actions.
## Resources
-  [Supabase](https://supabase.com/)
-  [dbt Core](https://docs.getdbt.com/docs/introduction#:~:text=dbt%20Core%20is%20an%20open,the%20quickstart%20for%20dbt%20Core.)
- [ dbt-focused Jaffle Shop project](https://jaffle.sh/)
