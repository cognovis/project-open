-- upgrade-3.4.0.5.1-3.4.0.5.2.sql

SELECT acs_log__debug('/packages/intranet-cost/sql/postgresql/upgrade/upgrade-3.4.0.5.1-3.4.0.5.2.sql','');


-------------------------------------------------------------
-- Determine the VAT type of a given cost item.
-- ToDo: Move the vat_type _into_ the im_cost as vat_type_id.
--

create or replace function im_cost_vat_type_from_cost_id (integer)
returns varchar as '
declare
	p_cost_id			alias for $1;

	v_cost_type_id			integer;
	v_cost_type			varchar;
	v_vat_string			varchar;
	v_vat_type			varchar;
	v_cost_is_invoice_or_quote_p	integer;
	v_internal_country_code		varchar;

	v_customer_country_code		varchar;
	v_customer_spain_p		integer;
	v_customer_eu_p			integer;

	v_provider_country_code		varchar;
	v_provider_spain_p		integer;
	v_provider_eu_p			integer;
begin
	-- Get the relevant information about the cost item
	SELECT
		c.cost_type_id,
		im_category_from_id(c.cost_type_id),
		trim(to_char(coalesce(c.vat,0), ''999.9''), ''0. ''),
		(select o.address_country_code from im_offices o where o.office_id = cust.main_office_id),
		(select o.address_country_code from im_offices o where o.office_id = prov.main_office_id)
	INTO
		v_cost_type_id,
		v_cost_type,
		v_vat_string,
		v_customer_country_code,
		v_provider_country_code
	FROM
		im_companies cust,
		im_companies prov,
		im_costs c
	WHERE
		c.cost_id = p_cost_id and
		c.customer_id = cust.company_id and
		c.provider_id = prov.company_id;

	-- Make sure we get a reasonable number after the trim() operation...
	IF '''' = v_vat_string THEN v_vat_string = ''0''; END IF;

	-- Determine the country_code of the internal company.
	SELECT	(select address_country_code from im_offices where office_id = c.main_office_id)
	INTO	v_internal_country_code
	from	im_companies c
	where	c.company_path = ''internal'';

	IF v_cost_type_id not in (3700,3702,3704,3706,3720,3724,3730,3732) THEN
		return ''invalid cost type: '' || v_cost_type;
	END IF;

	-- check customer characteristics
	IF v_customer_country_code = v_internal_country_code
		THEN v_customer_spain_p := 1;
		ELSE v_customer_spain_p := 0;
	END IF;
	RAISE NOTICE ''im_cost_vat_type_from_cost_id: v_customer_spain_p=%'', v_customer_spain_p;
	IF v_customer_country_code in (
			''ad'', ''at'', ''be'', ''bg'', ''cy'', ''cz'', ''de'', ''dk'', 
			''ee'', ''es'', ''fi'', ''fr'', ''gr'', ''hr'', ''hu'', ''ie'', 
			''it'', ''li'', ''lu'', ''mt'', ''nl'', ''no'', ''pl'', ''pt'', 
			''ro'', ''se'', ''si'', ''sk'', ''uk'') 
		THEN v_customer_eu_p := 1;
		ELSE v_customer_eu_p := 0;
	END IF;
	RAISE NOTICE ''im_cost_vat_type_from_cost_id: v_customer_eu_p=%'', v_customer_eu_p;


	-- check provider characteristics
	IF v_provider_country_code = v_internal_country_code
		THEN v_provider_spain_p := 1;
		ELSE v_provider_spain_p := 0;
	END IF;
	RAISE NOTICE ''im_cost_vat_type_from_cost_id: v_provider_spain_p=%'', v_provider_spain_p;
	IF v_provider_country_code in (
			''ad'', ''at'', ''be'', ''bg'', ''cy'', ''cz'', ''de'', ''dk'', 
			''ee'', ''es'', ''fi'', ''fr'', ''gr'', ''hr'', ''hu'', ''ie'', 
			''it'', ''li'', ''lu'', ''mt'', ''nl'', ''no'', ''pl'', ''pt'', 
			''ro'', ''se'', ''si'', ''sk'', ''uk'') 
		THEN v_provider_eu_p := 1;
		ELSE v_provider_eu_p := 0;
	END IF;
	RAISE NOTICE ''im_cost_vat_type_from_cost_id: v_provider_eu_p=%'', v_provider_eu_p;

	IF v_cost_type_id in (3700,3702,3730,3732)
		THEN v_cost_is_invoice_or_quote_p := 1;
		ELSE v_cost_is_invoice_or_quote_p := 0;
	END IF;
	RAISE NOTICE ''im_cost_vat_type_from_cost_id: v_cost_is_invoice_or_quote_p=%'', v_cost_is_invoice_or_quote_p;
	
	IF v_cost_is_invoice_or_quote_p > 0 THEN
		v_vat_type := ''Intl'';
		IF v_customer_eu_p THEN v_vat_type = ''EU''; END IF;
		IF v_customer_spain_p THEN v_vat_type = ''Domestic''; END IF;
		v_vat_type := v_vat_type || '' '' || v_vat_string || ''%'';
	ELSE
		v_vat_type := ''Intl'';
		IF v_provider_eu_p THEN v_vat_type = ''EU''; END IF;
		IF v_provider_spain_p THEN v_vat_type = ''Domestic''; END IF;
		v_vat_type := v_vat_type || '' '' || v_vat_string || ''%'';
	END IF;

        return v_vat_type;
end;' language 'plpgsql';



select
	cost_id,
	im_category_from_id(c.cost_type_id) as cost_type,
	(select o.address_country_code from im_offices o where o.office_id = cust.main_office_id) as cust_cc,
        (select o.address_country_code from im_offices o where o.office_id = prov.main_office_id) as prov_cc,
	im_cost_vat_type_from_cost_id (cost_id) as vat_type
from
	im_costs c,
	im_companies prov,
	im_companies cust
where
	c.customer_id = cust.company_id and
	c.provider_id = prov.company_id
order by
	cost_id
LIMIT 100;
