-- upgrade-3.4.1.0.0-3.4.1.0.1.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.1.0.0-3.4.1.0.1.sql','');



create or replace function im_project__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, varchar, integer, integer, integer, integer
) returns integer as '
DECLARE
	p_project_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date 	alias for $3;
	p_creation_user		alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_project_name		alias for $7;
	p_project_nr		alias for $8;
	p_project_path		alias for $9;
	p_parent_id		alias for $10;
	p_company_id		alias for $11;
	p_project_type_id	alias for $12;
	p_project_status_id	alias for $13;

	v_project_id		integer;
BEGIN
	v_project_id := acs_object__new (
		p_project_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_biz_objects (object_id) values (v_project_id);

	insert into im_projects (
		project_id, project_name, project_nr, 
		project_path, parent_id, company_id, project_type_id, 
		project_status_id 
	) values (
		v_project_id, p_project_name, p_project_nr, 
		p_project_path, p_parent_id, p_company_id, p_project_type_id, 
		p_project_status_id
	);
	return v_project_id;
end;' language 'plpgsql';

insert into im_biz_objects (object_id)
select	project_id
from	im_projects
where	project_id not in (
		select	object_id
		from	im_biz_objects
	)
;





-----------------------------------------------------------
-- Widgets
--

SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'offices', 'Offices', 'Offices',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
		select	
			p.office_id,
			p.office_name
		from 
			im_offices p
		where 
			p.office_status_id not in (161)
		order by 
			lower(office_name) 
	}}}'
);


-----------------------------------------------------------
-- Hard coded fields
--
SELECT im_dynfield_attribute_new (
	'im_company', 'company_name', 'Name', 'textbox_medium', 'string', 'f', 0, 't', 'im_companies'
);
SELECT im_dynfield_attribute_new (
	'im_company', 'company_path', 'Path', 'textbox_medium', 'string', 'f', 10, 't', 'im_companies'
);
SELECT im_dynfield_attribute_new (
	'im_company', 'main_office_id', 'Main Office', 'offices', 'integer', 'f', 20, 't', 'im_companies'
);
SELECT im_dynfield_attribute_new (
	'im_company', 'company_status_id', 'Status', 'category_company_status', 
	'integer', 'f', 30, 't', 'im_companies'
);
SELECT im_dynfield_attribute_new (
	'im_company', 'company_type_id', 'Type', 'category_company_type', 
	'integer', 'f', 40, 't', 'im_companies'
);


-----------------------------------------------------------
-- Hard coded fields
--

SELECT im_dynfield_attribute_new ('im_company', 'primary_contact_id', 'Primary Contact', 'customer_contact', 'integer', 'f', 100, 'f', 'im_companies');
SELECT im_dynfield_attribute_new ('im_company', 'accounting_contact_id', 'Accounting Contact', 'customer_contact', 'integer', 'f', 100, 'f', 'im_companies');


-- note                        | character varying(4000) |
-- referral_source             | character varying(1000) |
-- annual_revenue_id           | integer                 |
-- status_modification_date    | date                    |
-- old_company_status_id       | integer                 |
-- billable_p                  | character(1)            | default 'f'::bpchar
-- site_concept                | character varying(100)  |
-- manager_id                  | integer                 |
-- contract_value              | integer                 |
-- start_date                  | date                    |
-- vat_number                  | character varying(100)  |
-- default_vat                 | numeric(12,1)           | default 0
-- default_invoice_template_id | integer                 |
-- default_payment_method_id   | integer                 |
-- default_payment_days        | integer                 |
-- default_bill_template_id    | integer                 |
-- default_po_template_id      | integer                 |
-- default_delnote_template_id | integer                 |
-- invoice_template_id         | integer                 |
-- payment_method_id           | integer                 |
-- payment_days                | integer                 |
-- default_quote_template_id   | integer                 |
-- company_group_id            | integer                 |
-- business_sector_id          | integer                 |
-- default_tax                 | numeric(12,1)           | default 0

