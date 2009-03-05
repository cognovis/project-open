-- upgrade-3.4.0.4.0-3.4.0.5.0.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.4.0-3.4.0.5.0.sql','');


-- Changes from Malte to make ]po[ run with OpenACS 5.4 and Contacts

-- Fix the syntax error in acs_rel_type__drop_type
--
create or replace function acs_rel_type__drop_type (varchar,boolean)
returns integer as '
declare
  drop_type__rel_type               alias for $1;  
  drop_type__cascade_p              alias for $2;  -- default ''f''  
  v_cascade_p                       boolean;
begin
    -- XXX do cascade_p.
    -- JCD: cascade_p seems to be ignored in acs_o_type__drop_type anyway...

    if drop_type__cascade_p is null then 
	v_cascade_p := ''f'';
    else 
	v_cascade_p := drop_type__cascade_p;
    end if;

    delete from acs_rel_types
	  where rel_type = drop_type__rel_type;

    PERFORM acs_object_type__drop_type(drop_type__rel_type, 
                                       v_cascade_p);

    return 0; 
end;' language 'plpgsql';



---------------------------------------------------
-- Insert offices to parties and biz_objects
--

insert into parties (party_id)
select	office_id 
from	im_offices
where	office_id not in (select party_id from parties);

insert into im_biz_objects (object_id)
select	office_id
from	im_offices
where	office_id not in (select object_id from im_biz_objects);


---------------------------------------------------
-- Insert companies to parties and biz_objects
--
insert into parties (party_id)
select	company_id
from	im_companies
where	company_id not in (select party_id from parties);

insert into im_biz_objects (object_id)
select	company_id
from	im_companies
where	company_id not in (select object_id from im_biz_objects);











-------------------------------------------------------------------
-- !!!
-------------------------------------------------------------------


-- We need to fill acs_object_type_tables with the correct values
-- As the automated class generation cannot deal with this




CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer as '
DECLARE
	v_count			integer;
BEGIN
	select	count(*) into v_count from acs_object_type_tables
	where	object_type = ''person'' and table_name = ''users_contact'';
	IF v_count > 0 THEN return 0; END IF;

	insert into acs_object_type_tables values ('person','users_contact','user_id');

	RETURN 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();


-- users_contact has "user_id" as index column
update acs_object_type_tables set
	id_column = 'user_id'
where	object_type = 'person' and
	table_name = 'users_contact';


-- im_employees has "employee_id" as index column
update acs_object_type_tables set
	id_column = 'employee_id'
where	object_type = 'person' and
	table_name = 'im_employees';




CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer as '
DECLARE
	v_count			integer;
BEGIN
	select	count(*) into v_count from acs_object_type_tables
	where	object_type = ''person'' and table_name = ''parties'';
	IF v_count > 0 THEN return 0; END IF;

	insert into acs_object_type_tables values ('person','parties','party_id');

	RETURN 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();


-- Fix bad entry
update acs_attributes set table_name = 'persons' where object_type = 'person' and table_name is null;




insert into acs_object_type_tables (object_type,table_name,id_column)
values ('person','im_employees','employee_id');




insert into im_employees (employee_id)
select person_id
from persons
where person_id not in (select employee_id from im_employees);





create or replace function im_office__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, integer
) returns integer as '
declare
        p_office_id     alias for $1;
        p_object_type     alias for $2;
        p_creation_date   alias for $3;
        p_creation_user   alias for $4;
        p_creation_ip     alias for $5;
        p_context_id      alias for $6;

	p_office_name	alias for $7;
	p_office_path	alias for $8;
	p_office_type_id  alias for $9;
	p_office_status_id alias for $10;
	p_company_id	alias for $11;

        v_object_id     integer;
begin
	v_object_id := acs_object__new (
		p_office_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);
	insert into im_offices (
		office_id, office_name, office_path, 
		office_type_id, office_status_id, company_id
	) values (
		v_object_id, p_office_name, p_office_path, 
		p_office_type_id, p_office_status_id, p_company_id
	);

	-- make a party - required by contacts
	insert into parties (party_id) values (v_object_id);
	insert into im_biz_objects (object_id) values (v_object_id);

	return v_object_id;
end;' language 'plpgsql';


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
	insert into im_biz_objects (object_id) values (v_company_id);

	-- Set the link back from the office to the company
	update	im_offices
	set	company_id = v_company_id
	where	office_id = p_main_office_id;

	return v_company_id;
end;' language 'plpgsql';




create or replace function im_company__delete (integer) returns integer as '
DECLARE
	v_company_id	     alias for $1;
BEGIN
	-- make sure to remove links from all offices to this company.
	update im_offices
	set company_id = null
	where company_id = v_company_id;

	-- Erase the im_companies item associated with the id
	delete from im_companies
	where company_id = v_company_id;

	-- Delete entry from parties
	delete from parties where party_id = v_office_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_company_id;

	PERFORM acs_object__delete(v_company_id);

	return 0;
end;' language 'plpgsql';




-- Delete a single office (if we know its ID...)
create or replace function im_office__delete (integer) returns integer as '
DECLARE
	v_office_id		alias for $1;
BEGIN
	-- Erase the im_offices item associated with the id
	delete from im_offices
	where office_id = v_office_id;

	-- Delete entry from parties
	delete from parties where party_id = v_office_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_office_id;

	PERFORM	acs_object__delete(v_office_id);

	return 0;
end;' language 'plpgsql';




-- Make sure users_contact has a valid foreign key with
-- persons.

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer as '
DECLARE
	v_count			integer;
BEGIN
	select	count(*) into v_count
	from	pg_constraint 
	where	conname = ''users_contact_user_id_fk'';
	IF v_count > 0 THEN return 0; END IF;

	-- delete "ruins" from delete users?
	delete from users_contact
	where user_id not in (select person_id from persons);

	alter table users_contact 
	add constraint users_contact_user_id_fk foreign key (user_id) references persons(person_id);

	RETURN 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();




CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer as '
DECLARE
	v_count			integer;
BEGIN
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_companies'' and lower(column_name) = ''default_quote_template_id'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_companies
	add default_quote_template_id integer;

	alter table im_companies
	add constraint im_companies_default_quote_fk foreign key (default_quote_template_id) references im_categories;

	RETURN 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();





-- Disable the "active or potential" category, if not already disabled...
update im_categories
set enabled_p = 'f'
where category_id = 40;


