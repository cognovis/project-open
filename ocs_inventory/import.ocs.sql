---------------------------------------------------------------------------------
-- import.ocs.sql
--
-- Convert data from the OCS Inventory database to the ]po[ confdb format
---------------------------------------------------------------------------------


create or replace function inline_0 ()
returns integer as '
DECLARE
	row			RECORD;
	v_oid			integer;
	v_computer_type_id	integer;
	v_active_status_id	integer;
BEGIN

    v_active_status_id = 11700;


    for row in
	select	*
	from	hardware h
    loop

	v_oid := create im_conf_item__new (
		null,			-- p_conf_item_id
		''im_conf_item''	-- p_object_type
		now(),			-- p_creation_date
		624,			-- p_creation_user
		''0.0.0.0'',		-- p_creation_ip
		null,			-- p_context_id
	
		row.name,		-- p_conf_item_name
		row.deviceid,		-- p_conf_item_nr
		null,			-- p_conf_item_parent_id
		v_computer_type_id,	-- p_conf_item_type_id
		v_active_status_id	-- p_conf_item_status_id
	);


	IF v_office_id is NULL THEN
		select im_office__new (
			null, ''im_office'',
			now()::date, 0, ''0.0.0.0'', null,
			v_office_name,
			lower(trim(replace(v_office_name, '' '', ''_''))),
			170, 160, null
		) into v_office_id;
	END IF;

	IF v_company_id is NULL THEN
		select im_company__new (
			null, ''im_company'', now()::date,
			0, ''0.0.0.0'', null, 
			row.company_name,
			lower(trim(replace(row.company_name, '' '', ''_''))),
			v_office_id,
			57,
			46
		) into v_company_id;
	END IF;



 workgroup   | character varying(255)      |
 userdomain  | character varying(255)      |
 osname      | character varying(255)      |
 osversion   | character varying(255)      |
 oscomments  | character varying(255)      |
 processort  | character varying(255)      |
 processors  | integer		     | default 0
 processorn  | smallint		    |
 memory      | integer		     |
 swap	| integer		     |
 ipaddr      | character varying(255)      |
 etime       | timestamp without time zone |
 lastdate    | timestamp without time zone |
 lastcome    | timestamp without time zone |
 quality     | numeric(4,3)		| default 0.000
 fidelity    | bigint		      | default 1::bigint
 userid      | character varying(255)      |
 type	| integer		     |
 description | character varying(255)      |
 wincompany  | character varying(255)      |
 winowner    | character varying(255)      |
 winprodid   | character varying(255)      |
 winprodkey  | character varying(255)      |
 useragent   | character varying(50)       |
 checksum    | integer		     | default 131071


	v_company_status_id := 46;
	IF false = row.company_active_p THEN v_company_status_id := 48; END IF;
	v_company_type_id := 57;

	v_office_status_id := 160;
	IF false = row.office_active_p THEN v_office_status_id := 161; END IF;
	v_office_type_id := 170;
	IF false = row."IsMain" THEN v_office_type_id := 171; END IF;

	select	iso into v_country_code
	from	country_codes cc,
		"lktblCountry" lc
	where	lower(cc.country_name) = lower(lc."CountryNmDisplay")
		and lc."CountryID" = row. "CountryID";

	select	category_id into v_company_sector_id
	from	im_categories 
	where	category_type = ''Intranet Company Sector''
		and aux_int1 = row."CompSectorID";

	select	category_id into v_sales_potential_id
	from	im_categories 
	where	category_type = ''Intranet Company Sales Potential''
		and aux_int1 = row."ClassificationID";

	select	category_id into v_company_referral_source_id
	from	im_categories 
	where	category_type = ''Intranet Company Referral Type''
		and aux_int1 = row."CompSourceID";

	RAISE NOTICE ''Cli:%, Addr:%, Off:%, Comp:%, oid:%, cid:%, cc:%, sales:%'', 
	row.company_id, row.address_num, v_office_postfix, row.company_name, v_office_id, v_company_id,
	v_country_code, v_sales_potential_id;

	update im_companies set
		note =	coalesce(row."CompDesc", '''') || '' '' || 
			coalesce(row."RefFileDir", ''''),
		company_status_id = v_company_status_id,
		vat_number = row."VATNumber",
		provider_number = row."SupplierNumber",
		company_sector_id = v_company_sector_id,
		sales_potential_id = v_sales_potential_id,
		referral_type_id = v_company_referral_source_id,
		lxc_company_id = row."CompID"
	where	company_id = v_company_id;

	update im_offices set
		company_id = v_company_id,
		note = trim(
			coalesce(row."AddressTo", '''') || '' '' || 
			coalesce(row."AddInfo", '''') || '' '' || 
			coalesce(row."StProv", '''')
		),
		office_status_id = v_office_status_id,
		office_type_id = v_office_type_id,
		address_line1 = row."Add",
		address_line2 = row."Add2",
		address_city = row."City",
		address_postal_code = row."CodePost",
		address_country_code = v_country_code
	where	office_id = v_office_id;

    end loop;
    return 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

