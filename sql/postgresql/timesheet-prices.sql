


-- Get everything about a timesheet price
        select  p.*
        from    im_timesheet_prices p
        where   p.price_id = :price_id
;


-- Update Timesheet Prices
        update im_prices set
                package_name    = :package_name,
                label           = :label,
                name            = :name,
                url             = :url,
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

-- make sure the same price doesn't get defined twice 
create unique index im_timesheet_price_idx on im_timesheet_prices (
	uom_id, company_id, task_type_id, material_id, currency
);


------------------------------------------------------
--

-- Calculate a match value between a price list item and an invoice_item
-- The higher the match value the better the fit.

create or replace function im_timesheet_prices_calc_relevancy ( 
       integer, integer, integer, integer, integer, integer
) returns numeric as '
DECLARE
	v_price_company_id		alias for $1;	
	v_item_company_id		alias for $2;
	v_price_task_type_id		alias for $3;
	v_item_task_type_id		alias for $4;
	v_price_material_id		alias for $5;
	v_item_material_id		alias for $6;

	match_value			numeric;
	v_internal_company_id		integer;
BEGIN
	match_value := 0;

	select company_id
	into v_internal_company_id
	from im_companies
	where company_path=''internal'';

	-- Hard matches for task type
	if v_price_task_type_id = v_item_task_type_id then
		match_value := match_value + 4;
	end if;
	if not(v_price_task_type_id is null) 
		and v_price_task_type_id != v_item_task_type_id then
		match_value := match_value - 4;
	end if;

	if v_price_material_id = v_item_material_id then
		match_value := match_value + 1;
	end if;
	if not(v_price_material_id is null) 
		and v_price_material_id != v_item_material_id then
		match_value := match_value - 10;
	end if;

	-- Company logic - "Internal" doesnt give a penalty 
	-- but doesnt count as high as an exact match
	--
	if v_price_company_id = v_item_company_id then
		match_value := (match_value + 6)*2;
	end if;
	if v_price_company_id = v_internal_company_id then
		match_value := match_value + 1;
	end if;
	if v_price_company_id != v_internal_company_id 
		and v_price_company_id != v_item_company_id then
		match_value := match_value -10;
	end if;

	return match_value;
end;' language 'plpgsql';

