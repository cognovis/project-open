-- upgrade-3.2.2.0.0-3.2.3.0.0.sql

SELECT acs_log__debug('/packages/intranet-trans-invoices/sql/postgresql/upgrade/upgrade-3.2.2.0.0-3.2.3.0.0.sql','');


create or replace function im_trans_prices_calc_relevancy ( 
       integer, integer, integer, integer, integer, integer, integer, integer, integer, integer
) returns numeric as '
DECLARE
	v_price_company_id		alias for $1;		
	v_item_company_id		alias for $2;
	v_price_task_type_id		alias for $3;	
	v_item_task_type_id		alias for $4;
	v_price_subject_area_id		alias for $5;	
	v_item_subject_area_id		alias for $6;
	v_price_target_language_id	alias for $7;	
	v_item_target_language_id	alias for $8;
	v_price_source_language_id	alias for $9;	
	v_item_source_language_id	alias for $10;
	match_value			numeric;
	v_internal_company_id		integer;
	v_price_target_language		varchar(100);
	v_item_target_language		varchar(100);
	v_price_source_language		varchar(100);
	v_item_source_language		varchar(100);
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
	if not(v_price_task_type_id is null) and v_price_task_type_id != v_item_task_type_id then
		match_value := match_value - 4;
	end if;

	-- Default matching for source language:
	-- "de" <-> "de_DE" = + 1
	-- "de_DE" <-> "de_DE" = +3
	-- "es" <-> "de_DE" = -10
	if (v_price_source_language_id is not null) and  (v_item_source_language_id is not null) then
		-- only add or subtract match_values if both are defined...
		select	category
		into	v_price_source_language
		from	im_categories
		where	category_id = v_price_source_language_id;
	
		select	category
		into	v_item_source_language
		from	im_categories
		where	category_id = v_item_source_language_id;

		if substr(v_price_source_language,1,2) = substr(v_item_source_language,1,2) then
			-- the main part of the language have matched
			match_value := match_value + 2;
			if v_price_source_language_id = v_item_source_language_id then
				-- the main part have matched and the country variants are the same
				match_value := match_value + 1;
			end if;
		else
			match_value := match_value - 10;
		end if;
	end if;


	-- Default matching for target language:
	if (v_price_target_language_id is not null) and  (v_item_target_language_id is not null) then
		-- only add or subtract match_values if both are defined...
		select	category
		into	v_price_target_language
		from	im_categories
		where	category_id = v_price_target_language_id;
	
		select	category
		into	v_item_target_language
		from	im_categories
		where	category_id = v_item_target_language_id;

		if substr(v_price_target_language,1,2) = substr(v_item_target_language,1,2) then
			-- the main part of the language have matched
			match_value := match_value + 1;		
			if v_price_target_language_id = v_item_target_language_id then
				-- the main part have matched and the country variants are the same
				match_value := match_value + 1;
			end if;
		else
			match_value := match_value - 10;
		end if;
	end if;


	if v_price_subject_area_id = v_item_subject_area_id then
		match_value := match_value + 1;
	end if;
	if not(v_price_subject_area_id is null) and v_price_subject_area_id != v_item_subject_area_id then
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
	if v_price_company_id != v_internal_company_id and v_price_company_id != v_item_company_id then
		match_value := match_value -100;
	end if;

	return match_value;
end;' language 'plpgsql';


