------------------------------------------------------------
-- Companies
------------------------------------------------------------

-- Get everything about a company
select
	c.*,
	im_name_from_user_id(c.primary_contact_id) as primary_contact_name,
	im_email_from_user_id(c.primary_contact_id) as primary_contact_email,
	im_name_from_user_id(c.accounting_contact_id) as accounting_contact_name,
	im_email_from_user_id(c.accounting_contact_id) as accounting_contact_email,
	im_name_from_user_id(c.manager_id) as manager,
	im_category_from_id(c.company_status_id) as company_status,
	im_category_from_id(c.company_type_id) as company_type,
	im_category_from_id(c.annual_revenue_id) as annual_revenue,
	to_char(start_date,'Month DD, YYYY') as start_date,
	o.phone,
	o.fax,
	o.address_line1,
	o.address_line2,
	o.address_city,
	o.address_state,
	o.address_postal_code,
	o.address_country_code
from
	im_companies c,
	im_offices o
where
	c.company_id = :company_id
	and c.main_office_id = o.office_id
;

-- Get the company's country name
select cc.country_name 
from country_codes 
cc where cc.iso = :address_country_code

-- Select companies with permissions
-- Only show companies that a non-privileged user can see.
select
	c.*,
	c.primary_contact_id as company_contact_id,
	im_name_from_user_id(c.accounting_contact_id) as accounting_contact_name,
	im_email_from_user_id(c.accounting_contact_id) as accounting_contact_email,
	im_name_from_user_id(c.primary_contact_id) as company_contact_name,
	im_email_from_user_id(c.primary_contact_id) as company_contact_email,
	im_category_from_id(c.company_type_id) as company_type,
	im_category_from_id(c.company_status_id) as company_status
from
	(       select
			c.*
		from
			im_companies c,
			acs_rels r
		where
			c.company_id = r.object_id_one
			and r.object_id_two = :user_id
			$where_clause
	) c
where
	1=1
;


-- Get the list of all users who are "members" or the Company
-- (i.e. Key accounts and users associated with the Company)
select distinct
	u.user_id,
	im_name_from_user_id(u.user_id) as name,
	im_email_from_user_id(u.user_id) as email
from
	users u,
	acs_rels r
where
	r.object_id_one = :company_id
	and r.object_id_two = u.user_id
	and not exists (
		select  member_id
		from    group_member_map m,
			membership_rels mr
		where   m.member_id = u.user_id
			and m.rel_id = mr.rel_id
			and mr.member_state = 'approved'
			and m.group_id = [im_employee_group_id]
	);


-- Update a company
update im_companies set
	company_name	    = :company_name,
	company_path	    = :company_path,
	vat_number	      = :vat_number,
	company_status_id       = :company_status_id,
	old_company_status_id   = :old_company_status_id,
	company_type_id = :company_type_id,
	referral_source	 = :referral_source,
	start_date	      = :start_date,
	annual_revenue_id       = :annual_revenue_id,
	contract_value	  = :contract_value,
	site_concept	    = :site_concept,
	manager_id	      = :manager_id,
	billable_p	      = :billable_p,
	note		    = :note
where
	company_id = :company_id;


-- Update a Company Office 
-- Set the company's address
update im_offices set
	office_name = :office_name,
	phone = :phone,
	fax = :fax,
	address_line1 = :address_line1,
	address_line2 = :address_line2,
	address_city = :address_city,
	address_state = :address_state,
	address_postal_code = :address_postal_code,
	address_country_code = :address_country_code
where
	office_id = :main_office_id;


-- Creating a Company
-- => First create it's main_office:

select im_office__new (
	null,
	'im_office',
	:creation_date,
	:creation_user,
	:creation_ip,
	:context_id,
	:office_name,
	:office_path,
	:office_type_id,
	:office_status_id,
	:company_id
);

-- Create the Company with a pointer to the main Office
select im_company__new (
	null,
	'im_company',
	:creation_date,
	:creation_user,
	:creation_ip,
	:context_id,
	:company_name,
	:company_path,
	:main_office_id,
	:company_type_id,
	:company_status_id
);


---------------------------------------------------------
-- Companies
--
-- We store simple information about a company.
-- All contact information goes in the associated
-- offices.
--

create table im_companies (
	company_id		integer
				constraint im_companies_pk
				primary key
				constraint im_companies_cust_id_fk
				references acs_objects,
	company_name		varchar(1000) not null
				constraint im_companies_name_un unique,
				-- where are the files in the filesystem?
	company_path		varchar(100) not null
				constraint im_companies_path_un unique,
	main_office_id		integer not null
				constraint im_companies_office_fk
				references im_offices,
	deleted_p		char(1) default('f')
				constraint im_companies_deleted_p
				check(deleted_p in ('t','f')),
	company_status_id	integer not null
				constraint im_companies_cust_stat_fk
				references im_categories,
	company_type_id 	integer not null
				constraint im_companies_cust_type_fk
				references im_categories,
	crm_status_id		integer
				constraint im_companies_crm_status_fk
				references im_categories,
	primary_contact_id	integer
				constraint im_companies_prim_cont_fk
				references users,
	accounting_contact_id   integer
				constraint im_companies_acc_cont_fk
				references users,
	note			text,
	referral_source		text,
	annual_revenue_id	integer
				constraint im_companies_ann_rev_fk
				references im_categories,
				-- keep track of when status is changed
	status_modification_date date,
				-- and what the old status was
	old_company_status_id   integer
				constraint im_companies_old_cust_stat_fk
				references im_categories,
				-- is this a company we can bill?
	billable_p		char(1) default('f')
				constraint im_companies_billable_p_ck
				check(billable_p in ('t','f')),
				-- What kind of site does the company want?
	site_concept		varchar(100),
				-- Who in Client Services is the manager?
	manager_id		integer
				constraint im_companies_manager_fk
				references users,
				-- How much do they pay us?
	contract_value		integer,
				-- When does the company start?
	start_date		date,
	vat_number		varchar(100),
				-- Default value for VAT
	default_vat		numeric(12,1) default 0,
				-- default payment days
	default_payment_days	integer,
				-- Default invoice template
	default_invoice_template_id	 integer
				constraint im_companies_def_invoice_template_fk
				references im_categories,
				-- Default payment method
	default_payment_method_id	 integer
				constraint im_companies_def_invoice_payment_fk
				references im_categories
);



--------------------------------------------------------------
-- Offices
--
-- An office is a physical place belonging to the company itself
-- or to a company.
--

create table im_offices (
	office_id		integer 
				constraint im_offices_office_id_pk 
				primary key
				constraint im_offices_office_id_fk 
				references acs_objects,
	office_name		varchar(1000) not null
				constraint im_offices_name_un unique,
	office_path		varchar(100) not null
				constraint im_offices_path_un unique,
	office_status_id	integer not null
				constraint im_offices_cust_stat_fk
				references im_categories,
	office_type_id		integer not null
				constraint im_offices_cust_type_fk
				references im_categories,
				-- "pointer" back to the company of the office
				-- no foreign key to companies yet - we still
				-- need to define the table ..
	company_id		integer,
				-- is this office and contact information public?
	public_p		char(1) default 'f'
				constraint im_offices_public_p_ck 
				check(public_p in ('t','f')),
	phone			varchar(50),
	fax			varchar(50),
	address_line1		varchar(80),
	address_line2		varchar(80),
	address_city		varchar(80),
	address_state		varchar(80),
	address_postal_code	varchar(80),
	address_country_code	char(2) 
				constraint if_address_country_code_fk 
				references country_codes(iso),
	contact_person_id	integer 
				constraint im_offices_cont_per_fk
				references users,
	landlord		text,
	--- who supplies the security service, the code for
	--- the door, etc.
	security		text,
	note			text
);
