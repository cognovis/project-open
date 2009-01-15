-- upgrade-3.4.0.4.0-3.4.0.5.0.sql
-- Changes from Malte to make ]po[ run with OpenACs 5.4 and Contacts


create or replace function im_company__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, integer
) returns integer as '
DECLARE
	p_company_id      alias for $1;
	p_object_type     alias for $2;
	p_creation_date   alias for $3;
	p_creation_user   alias for $4;
	p_creation_ip     alias for $5;
	p_context_id      alias for $6;

	p_company_name	      alias for $7;
	p_company_path	      alias for $8;
	p_main_office_id      alias for $9;
	p_company_type_id     alias for $10;
	p_company_status_id   alias for $11;

	v_company_id	      integer;
BEGIN
	v_company_id := acs_object__new (
		p_company_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_companies (
		company_id, company_name, company_path, 
		company_type_id, company_status_id, main_office_id
	) values (
		v_company_id, p_company_name, p_company_path, 
		p_company_type_id, p_company_status_id, p_main_office_id
	);

	-- Make a party - required for contacts
	insert into parties (party_id) values (v_company_id);

	-- Set the link back from the office to the company
	update	im_offices
	set	company_id = v_company_id
	where	office_id = p_main_office_id;

	return v_company_id;
end;' language 'plpgsql';
