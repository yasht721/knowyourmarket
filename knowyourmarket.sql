
-- Creating Table

CREATE TABLE IF NOT EXISTS public.market
(
    sr_no integer NOT NULL,
    cap_type character varying(100) COLLATE pg_catalog."default",
    name character varying(100) COLLATE pg_catalog."default",
    ticker character varying(100),
	sub_sector character varying(200) COLLATE pg_catalog."default",
    market_cap integer,
    close_price integer,
    CONSTRAINT market_pkey PRIMARY KEY (sr_no)
)

-- -- Data cleaning

select
	*
from public."market"
where 
	market_cap > 750



	-- Cleaning Data Points

create table public.cleaned_market as (

select
 *
from 
	public.market
where 
	market_cap > 750
)

CREATE TABLE public.cleaned_market (
    sr_no INT,
    cap_type VARCHAR(255),
    name VARCHAR(255),
    ticker VARCHAR(50),
    sub_sector VARCHAR(255),
    market_cap BIGINT,
    close_price int
);

	-- Inserting Data

insert into public.cleaned_market (sr_no, cap_type, name, ticker, sub_sector, market_cap, close_price)
select
	sr_no, cap_type, name, ticker, sub_sector, market_cap, close_price
from
	public.market
where
	sub_sector is not null and market_cap > 750

-- Data Analysis

	-- Sector ranked by Cap_type
	
with main_table as (
select
	sub_sector,
	cap_type,
	sum(market_cap) as total_cap
from 
	public.cleaned_market
group by 1,2
order by 3 desc
)

select
	*,
	rank() over(partition by cap_type order by total_cap desc) as rnk
from 
	main_table
order by rnk asc, total_cap desc


-- Market_Cap distributed by sectors

select
	cap_type,
	count(distinct(sub_sector)),
	sum(market_cap)
from
	public.cleaned_market
group by 1


-- Market Cap by Cap Type

	
select
cap_type,
sum(market_cap)
	from public.cleaned_market
group by 1
order by 2 desc


-- Market Cap by Sector allocation

select 
	sub_sector,
	sum(market_cap)
from 
	public.cleaned_market
group by 1
order by 2 desc

-- -- Understanding the distribution of marketcap (Nifty 100)


-- --- Finding outliner in large cap

WITH PercentileCalc AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY market_cap) AS percentile_25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY market_cap) AS percentile_50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY market_cap) AS percentile_75,
        ((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY market_cap)) - (PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY market_cap))) AS IQR
    FROM
        public.cleaned_market
    WHERE
        cap_type = 'Large Cap'
)
SELECT
    cm.name,
    cm.market_cap,
	(pc.percentile_75 + (1.5 * pc.IQR)) as higher_fence
FROM
    public.cleaned_market cm,
    PercentileCalc pc
WHERE
    cm.cap_type = 'Large Cap' and
	market_cap > pc.percentile_75 + (1.5 * pc.IQR)

	-- 8% of the data is an outliner


-- Finding outliner in Mid Cap (Nifty Mid Cap 150)


WITH PercentileCalc AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY market_cap) AS percentile_25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY market_cap) AS percentile_50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY market_cap) AS percentile_75,
        ((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY market_cap)) - (PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY market_cap))) AS IQR
    FROM
        public.cleaned_market
    WHERE
        cap_type = 'Mid Cap'
)
SELECT
    cm.name,
    cm.market_cap,
	(pc.percentile_75 + (1.5 * pc.IQR)) as higher_fence,
	(pc.percentile_25 - (1.5 * pc.IQR)) as lower_fence
FROM
    public.cleaned_market cm,
    PercentileCalc pc
WHERE
    cm.cap_type = 'Mid Cap' 
order by  market_cap desc

	-- No Outliners found in Mid Cap


-- Finding Outliner in Small Cap (Nifty 250 Small Cap)

WITH PercentileCalc AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY market_cap) AS percentile_25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY market_cap) AS percentile_50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY market_cap) AS percentile_75,
        ((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY market_cap)) - (PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY market_cap))) AS IQR
    FROM
        public.cleaned_market
    WHERE
        cap_type = 'Small Cap' and sr_no <= 500
	
)
SELECT
    cm.name,
    cm.market_cap,
	(pc.percentile_75 + (1.5 * pc.IQR)) as higher_fence,
	(pc.percentile_25 - (1.5 * pc.IQR)) as lower_fence
FROM
    public.cleaned_market cm,
    PercentileCalc pc
WHERE
    cm.cap_type = 'Small Cap' and sr_no <= 500
order by 2 desc

   -- No Outliner found in Small Cap
