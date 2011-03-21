-- upgrade-3.2.10.0.0-3.2.11.0.0.sql

SELECT acs_log__debug('/packages/intranet-trans-invoices/sql/postgresql/upgrade/upgrade-3.2.10.0.0-3.2.11.0.0.sql','');


create or replace function inline_0 ()
returns integer as '
DECLARE
	v_count		integer;
BEGIN
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_trans_prices'' and lower(column_name) = ''file_type_id'';
	IF v_count > 0 THEN return 1; END IF;

	alter table im_trans_prices add file_type_id integer
	constraint im_trans_prices_file_type_fk	references im_categories;

	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();


create or replace function inline_0 ()
returns integer as '
DECLARE
	v_count		integer;
BEGIN
	select	count(*) into v_count from pg_indexes
	where	lower(indexname) = ''im_trans_price_idx'';
	IF v_count = 0 THEN return 1; END IF;

	-- Create a new index to incorporate file_type
	drop index im_trans_price_idx;

	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();



-- make sure the same price doesn't get defined twice
create unique index im_trans_price_idx on im_trans_prices (
        uom_id, company_id, task_type_id, target_language_id,
        source_language_id, subject_area_id, file_type_id, currency
);


SELECT im_category_new(600, 'MS-Word', 'Intranet Translation File Type');
update im_categories set aux_string1 = 'doc' where category_id = 600;

SELECT im_category_new(602, 'MS-Excel', 'Intranet Translation File Type');
update im_categories set aux_string1 = 'xls' where category_id = 602;

SELECT im_category_new(604, 'MS-PowerPoint', 'Intranet Translation File Type');
update im_categories set aux_string1 = 'ppt' where category_id = 604;




create or replace function im_file_type_from_trans_task (integer)
returns integer as '
DECLARE
        p_task_id	alias for $1;
	
	v_task_name	varchar;
	v_extension	varchar;
	v_result	integer;
BEGIN
	select	task_filename
	into	v_task_name 
	from	im_trans_tasks
	where	task_id = p_task_id;

	v_extension := lower(substring(v_task_name from length(v_task_name)-2));
	-- RAISE NOTICE ''%'', v_extension;

	select	min(category_id)
	into	v_result
	from	im_categories
	where	category_type = ''Intranet Translation File Type''
		and aux_string1 = v_extension;

        return v_result;
end;' language 'plpgsql';





-- Compatibility with previous version
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
BEGIN
	return im_trans_prices_calc_relevancy(
		v_price_company_id,
		v_item_company_id,
		v_price_task_type_id,
		v_item_task_type_id,
		v_price_subject_area_id,
		v_item_subject_area_id,
		v_price_target_language_id,
		v_item_target_language_id,
		v_price_source_language_id,
		v_item_source_language_id,
		0, 0
	);
end;' language 'plpgsql';



-- New procedure with added filetype
create or replace function im_trans_prices_calc_relevancy ( 
       integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer
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
	v_price_file_type_id		alias for $11;
	v_item_file_type_id		alias for $12;

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
		match_value := match_value + 8;
	end if;
	if not(v_price_task_type_id is null) and v_price_task_type_id != v_item_task_type_id then
		match_value := match_value - 8;
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
			match_value := match_value - 20;
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
			match_value := match_value - 20;
		end if;
	end if;

	-- Subject Area
	if v_price_subject_area_id = v_item_subject_area_id then
		match_value := match_value + 1;
	end if;
	if not(v_price_subject_area_id is null) and v_price_subject_area_id != v_item_subject_area_id then
		match_value := match_value - 20;
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


	-- File Type
	if v_price_file_type_id = v_item_file_type_id then
		match_value := match_value + 1;
	end if;
	if not(v_price_file_type_id is null) and v_price_file_type_id != v_item_file_type_id then
		match_value := match_value - 10;
	end if;


	return match_value;
end;' language 'plpgsql';


