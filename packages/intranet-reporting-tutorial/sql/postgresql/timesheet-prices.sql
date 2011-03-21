------------------------------------------------------------
-- Timesheet Prices 
------------------------------------------------------------

-- Get everything about a timesheet price
select  p.*
from    im_timesheet_prices p
where   p.price_id = :price_id
;


-- Update Timesheet Prices
update im_prices set
	package_name    = :package_name,
	label	   = :label,
	name	    = :name,
	url	     = :url,
	sort_order      = :sort_order,
	parent_price_id  = :parent_price_id
where
	price_id = :price_id
;


-- Insert Timesheet Prices
insert into im_timesheet_prices (
	price_id,
	uom_id,
	company_id,
	task_type_id,
	material_id,
	currency,
	price
) values (
	:price_id,
	:uom_id,
	:company_id,
	:task_type_id,
	:material_id,
	:currency,
	:amount
)


-- Delete from timesheet prices
delete from im_timesheet_prices
where price_id in ([join $price_list ","])


---------------------------------------------------------
-- Timesheet Prices
--
-- The price model is very specific to every consulting business,
-- so we need to allow maximum customization.
-- On the TCL API-Level we asume that we are able to determine
-- a price for every im_timesheet_task, given the im_company and the
-- im_project.
-- What is missing here are promotions and other types of 
-- exceptions. However, discounts are handled on the level
-- of invoice, together with VAT and other taxes.
--
-- The price model for the Timesheet Industry is based on
-- the variables:
--	- UOM: Unit of Measure: Hours, Days, Units (licences), ...
--	- Customer: There may be different rates for each customer
--	- Material
--	- Task Type

create sequence im_timesheet_prices_seq start 10000;
create table im_timesheet_prices (
	price_id		integer 
				constraint im_timesheet_prices_pk
				primary key,
	--
	-- "Input variables"
	uom_id			integer not null 
				constraint im_timesheet_prices_uom_id
				references im_categories,
	company_id		integer not null 
				constraint im_timesheet_prices_company_id
				references im_companies,
	task_type_id		integer
				constraint im_timesheet_prices_task_type_id
				references im_categories,
	material_id		integer
				constraint im_timesheet_prices_material_fk
				references im_materials,
	valid_from		timestamptz,
	valid_through		timestamptz,
				-- make sure the end date is after start date
				constraint im_timesheet_prices_date_const
				check(valid_through - valid_from >= 0),
	--
	-- "Output variables"
	currency		char(3) references currency_codes(ISO),
	price			numeric(12,4)
);
