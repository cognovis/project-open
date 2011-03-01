------------------------------------------------------------
-- Translation Prices
------------------------------------------------------------

-- Get everything about a Trans Price
select  p.*,
	price as amount
from    im_trans_prices p
where   p.price_id = :price_id


-- Get the list of all Trans Prices for a Project
select
	p.*,
	c.company_path as company_short_name,
	im_category_from_id(uom_id) as uom,
	im_category_from_id(task_type_id) as task_type,
	im_category_from_id(target_language_id) as target_language,
	im_category_from_id(source_language_id) as source_language,
	im_category_from_id(subject_area_id) as subject_area
from
	im_trans_prices p
	LEFT JOIN
		im_companies c USING (company_id)
where
	p.company_id=:company_id
order by
	currency,
	uom_id,
	target_language_id desc,
	task_type_id desc,
	source_language_id desc
;


-- Update a Trans price
update im_trans_prices set
	uom_id = :uom_id,
	task_type_id = :task_type_id,
	target_language_id = :target_language_id,
	source_language_id = :source_language_id,
	subject_area_id = :subject_area_id,
	currency = :currency,
	price = :amount,
	note = :note
where price_id = :price_id;


-- Insert a new Trans Price
insert into im_trans_prices (
	price_id,
	uom_id,
	company_id,
	task_type_id,
	target_language_id,
	source_language_id,
	subject_area_id,
	currency,
	price,
	note
) values (
	:price_id,
	:uom_id,
	:company_id,
	:task_type_id,
	:target_language_id,
	:source_language_id,
	:subject_area_id,
	:currency,
	:amount,
	:note
);


-- Delete a number of Trans Prices
delete from im_trans_prices
where price_id in ([join $price_list ","]);


--  Calculate the price for the specific service.
--  Complicated undertaking, because the price depends on a number of variables,
--  depending on client etc. As a solution, we act like a search engine, return
--  all prices and rank them according to relevancy. We take only the first
--  (=highest rank) line for the actual price proposal.
-- 
select
	p.price_id,
	p.relevancy as price_relevancy,
	trim(' ' from to_char(p.price,:number_format)) as price,
	p.company_id as price_company_id,
	p.uom_id as uom_id,
	p.task_type_id as task_type_id,
	p.target_language_id as target_language_id,
	p.source_language_id as source_language_id,
	p.subject_area_id as subject_area_id,
	p.valid_from,
	p.valid_through,
	p.price_note,
	c.company_path as price_company_name,
	im_category_from_id(p.uom_id) as price_uom,
	im_category_from_id(p.task_type_id) as price_task_type,
	im_category_from_id(p.target_language_id) as price_target_language,
	im_category_from_id(p.source_language_id) as price_source_language,
	im_category_from_id(p.subject_area_id) as price_subject_area
from  (
		(select
			im_trans_prices_calc_relevancy (
				p.company_id,:company_id,
				p.task_type_id, :task_type_id,
				p.subject_area_id, :subject_area_id,
				p.target_language_id, :target_language_id,
				p.source_language_id, :source_language_id
			) as relevancy,
			p.price_id,
			p.price,
			p.company_id,
			p.uom_id,
			p.task_type_id,
			p.target_language_id,
			p.source_language_id,
			p.subject_area_id,
			p.valid_from,
			p.valid_through,
			p.note as price_note
		from im_trans_prices p
		where
			uom_id=:task_uom_id
			and currency=:invoice_currency
		)
	) p,
	im_companies c
where
	p.company_id=c.company_id
	and relevancy >= 0
order by
	p.relevancy desc,
	p.company_id,
	p.uom_id
;




---------------------------------------------------------
-- Translation Prices
--
-- The price model is very specific to every translation business,
-- so we need to allow maximum customization.
-- On the TCL API-Level we asume that we are able to determine
-- a price for every im_task, given the im_company and the
-- im_project.
-- What is missing here are promotions and other types of 
-- exceptions. However, discounts are handled on the level
-- of invoice, together with VAT and other taxes.
--
-- The price model for the Translation Industry is based on
-- the variables:
--	- UOM: Unit of Measure: Hours, source words, lines,...
--	- Company: There may be different rates for each company
--	- Task Type
--	- Target language
--	- Source language
--	- Subject Area

create sequence im_trans_prices_seq start 10000;
create table im_trans_prices (
	price_id		integer 
				constraint im_trans_prices_pk
				primary key,
	--
	-- "Input variables"
	uom_id			integer not null 
				constraint im_trans_prices_uom_id
				references im_categories,
	company_id		integer not null 
				constraint im_trans_prices_company_id
				references im_companies,
	task_type_id		integer
				constraint im_trans_prices_task_type_id
				references im_categories,
	target_language_id	integer
				constraint im_trans_prices_target_lang
				references im_categories,
	source_language_id	integer
				constraint im_trans_prices_source_lang
				references im_categories,
	subject_area_id		integer
				constraint im_trans_prices_subject_are
				references im_categories,
	valid_from		timestamptz,
	valid_through		timestamptz,
				-- make sure the end date is after start date
				constraint im_trans_prices_date_const
				check(valid_through - valid_from >= 0),
	--
	-- "Output variables"
	currency		char(3) references currency_codes(ISO)
				constraint im_trans_prices_currency_nn
				not null,
	price			numeric(12,4)
				constraint im_trans_prices_price_nn
				not null,
	note			varchar(1000)
);
