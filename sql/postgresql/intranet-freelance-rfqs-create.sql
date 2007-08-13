-- /packages/intranet-freelance-rfqs/sql/postgresql/intranet-freelance-rfqs-create.sql
--
-- ]project-open[ Freelance RFQ
--
-- Copyright (C) 2007 Project/Open
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>


-------------------------------------------------------------
-- Freelance RFQ
--

SELECT acs_object_type__create_type (
	'im_freelance_rfq',		-- object_type
	'Freelance RFQ',		-- pretty_name
	'Freelance RFQs',		-- pretty_plural
	'acs_object',			-- supertype
	'im_freelance_rfqs',		-- table_name
	'rfq_id',			-- id_column
	'im_freelance_rfqs',		-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_freelance_rfq__name'	-- name_method
);


create table im_freelance_rfqs (
	rfq_id			integer
				constraint im_freelance_rfq_id_pk
				primary key
				constraint im_freelance_rfq_id_fk
				references acs_objects,
	rfq_name		varchar(400),
	rfq_project_id		integer
				constraint im_freelance_rfq_project_fk
				references im_projects,
	rfq_status_id		integer
				constraint im_freelance_rfq_status_fk
				references im_categories,
	rfq_type_id		integer
				constraint im_freelance_rfq_type_fk
				references im_categories,
	rfq_start_date		timestamptz,
	rfq_end_date		timestamptz,
	rfq_units		numeric(12,2),
	rfq_uom_id		integer
				constraint im_freelance_rfq_uom_units_fk
				references im_categories,
	rfq_workflow_key	varchar(100)
				constraint im_freelance_rfq_uom_wf_key_fk
				references wf_workflows,
	rfq_invite_mail_templ	integer
				constraint im_freelance_rfq_inv_mail_templ_fk
				references im_categories,
	rfq_confirm_mail_templ	integer
				constraint im_freelance_rfq_conf_mail_templ_fk
				references im_categories,
	rfq_decline_mail_templ	integer
				constraint im_freelance_rfq_decl_mail_templ_fk
				references im_categories,
	rfq_description		text,
	rfq_note		text
);


create index im_freelance_rfqs_project_idx on im_freelance_rfqs (rfq_project_id);



-------------------------------------------------------------
-- Status & Type Categories

-- 4400-4449    Intranet Freelance RFQ

delete from im_categories where category_type = 'Intranet Trans RFQ Overall Status';
delete from im_categories where category_type = 'Intranet Trans RFQ Type';
delete from im_categories where category_type = 'Intranet Trans RFQ Status';

-- Intranet Freelance RFQ Type
delete from im_categories where category_type = 'Intranet Freelance RFQ Type';

INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE, AUX_STRING1)
VALUES (4400,'Request for Availability','Intranet Freelance RFQ Type', 'request_for_availability_wf');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE, AUX_STRING1)
VALUES (4402,'Request for Quotation','Intranet Freelance RFQ Type', 'request_for_quotation_wf');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE, AUX_STRING1)
VALUES (4404,'Reverse Auction','Intranet Freelance RFQ Type', 'reverse_auction_wf');


-- Intranet Freelance RFQ Status
delete from im_categories where category_type = 'Intranet Freelance RFQ Status';

INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (4420,'Open','Intranet Freelance RFQ Status');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (4422,'Closed','Intranet Freelance RFQ Status');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (4424,'Canceled','Intranet Freelance RFQ Status');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (4426,'Deleted','Intranet Freelance RFQ Status');


-- intranet-freelance_rfqs: Creating status and type views
create or replace view im_freelance_rfq_type as
select	category_id as freelance_rfq_type_id,
        category as freelance_rfq_type
from    im_categories
where   category_type = 'Intranet Freelance RFQ Type';


create or replace view im_freelance_rfq_status as
select	category_id as freelance_rfq_status_id,
        category as freelance_rfq_status
from    im_categories
where   category_type = 'Intranet Freelance RFQ Status';



-------------------------------------------------------------
-- Status & Type Categories

-- 4450-4499    Intranet Freelance RFQ Answer



-- Intranet Freelance RFQ Answer Type
delete from im_categories where category_type = 'Intranet Freelance RFQ Answer Type';

INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE, AUX_STRING1)
VALUES (4450,'Default','Intranet Freelance RFQ Answer Type', 'request_for_availability_wf');


-- Intranet Freelance RFQ Answer Status
delete from im_categories where category_type = 'Intranet Freelance RFQ Answer Status';

INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (4470,'Invited','Intranet Freelance RFQ Answer Status');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (4472,'Confirmed','Intranet Freelance RFQ Answer Status');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (4474,'Declined','Intranet Freelance RFQ Answer Status');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (4476,'Canceled','Intranet Freelance RFQ Answer Status');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (4478,'Closed','Intranet Freelance RFQ Answer Status');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (4499,'Deleted','Intranet Freelance RFQ Answer Status');


-- intranet-freelance_rfqs: Creating status and type views
create or replace view im_freelance_rfq_answer_type as
select	category_id as freelance_rfq_type_id,
        category as freelance_rfq_type
from    im_categories
where   category_type = 'Intranet Freelance RFQ Answer Type';


create or replace view im_freelance_rfq_answer_status as
select	category_id as freelance_rfq_status_id,
        category as freelance_rfq_status
from    im_categories
where   category_type = 'Intranet Freelance RFQ Answer Status';




-------------------------------------------------------------
-- Creator/Deletor functions


-- Delete a single rfq (if we know its ID...)
create or replace function im_freelance_rfq__delete (integer)
returns integer as '
DECLARE
	p_freelance_rfq_id		alias for $1;
begin
	-- Erase the im_freelance_rfqs entry
	delete from	im_freelance_rfqs
	where		rfq_id = p_freelance_rfq_id;

	-- Erase the object
	PERFORM acs_object__delete(p_freelance_rfq_id);
	return 0;
end' language 'plpgsql';


create or replace function im_freelance_rfq__name (integer)
returns varchar as '
DECLARE
	p_freelance_rfqs_id		alias for $1;
	v_name  varchar(40);
begin
	select	rfq_name
	into	v_name
	from	im_freelance_rfqs
	where	rfq_id = p_freelance_rfqs_id;

	return v_name;
end;' language 'plpgsql';


create or replace function im_freelance_rfq__new (
	integer, varchar, timestamptz, integer,	varchar, integer, 
	varchar, integer, integer, integer
) returns integer as '
declare
	p_freelance_rfq_id		alias for $1;	-- freelance_rfq_id default null
	p_object_type		alias for $2;	-- object_type default ''im_freelance_rfq''
	p_creation_date		alias for $3;	-- creation_date default now()
	p_creation_user		alias for $4;	-- creation_user
	p_creation_ip		alias for $5;	-- creation_ip default null
	p_context_id		alias for $6;	-- context_id default null

	p_rfq_name		alias for $7;	-- freelance_rfq_name
	p_project_id		alias for $8;	-- project_id
	p_type_id		alias for $9;	-- project_id
	p_status_id		alias for $10;	-- project_id
	
	v_freelance_rfq_id		integer;
    begin
	v_freelance_rfq_id := acs_object__new (
		p_freelance_rfq_id,		-- cost_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,		-- creation_ip
		p_context_id		-- context_id
	);

	insert into im_freelance_rfqs (
		rfq_id,
		rfq_name,
		rfq_project_id,
		rfq_type_id,
		rfq_status_id
	) values (
		v_freelance_rfq_id,
		p_rfq_name,
		p_project_id,
		p_type_id,
		p_status_id
	);

	return v_freelance_rfq_id;
end;' language 'plpgsql';



-------------------------------------------------------------
-- Freelance RFQs Menu System
--

create or replace function inline_0 ()
returns integer as'
declare
	-- Menu IDs
	v_menu			integer;
	v_project_menu		integer;

	-- Groups
	v_accounting		integer;
	v_senman		integer;
	v_sales			integer;
	v_proman		integer;

begin
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_sales from groups where group_name = ''Sales'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';

    select menu_id
    into v_project_menu
    from im_menus
    where label=''project'';

    v_menu := im_menu__new (
	null,			-- p_menu_id
	''acs_object'',		-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	''intranet-freelance-rfqs'',	-- package_name
	''project_freelance_rfqs'',	-- label
	''RFQs'',		-- name
	''/intranet-freelance-rfqs/index?view=default'',  -- url
	100,			-- sort_order
	v_project_menu,		-- parent_menu_id
	null			-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_sales, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as'
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu		integer;

	-- Groups
	v_accounting		integer;
	v_senman		integer;
	v_sales			integer;
	v_proman		integer;
	v_freelance		integer;
begin
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_sales from groups where group_name = ''Sales'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_freelance from groups where group_name = ''Freelancers'';

    select menu_id
    into v_main_menu
    from im_menus
    where label=''main'';

    v_menu := im_menu__new (
	null,			-- p_menu_id
	''acs_object'',		-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	''intranet-freelance-rfqs'',	-- package_name
	''freelance_rfqs'',	-- label
	''RFQs'',		-- name
	''/intranet-freelance-rfqs/index'',  -- url
	130,			-- sort_order
	v_main_menu,		-- parent_menu_id
	null			-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_sales, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_freelance, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-------------------------------------------------------------
-- Permissions and Privileges
--
select acs_privilege__create_privilege('add_freelance_rfqs','Add Freelance-RFQs','Add Freelance-RFQs');
select acs_privilege__add_child('admin', 'add_freelance_rfqs');

select acs_privilege__create_privilege('view_freelance_rfqs','View Freelance-RFQs','View Freelance-RFQs');
select acs_privilege__add_child('admin', 'view_freelance_rfqs');

select acs_privilege__create_privilege('view_freelance_rfqs_all','View All Freelance-RFQs','View All Freelance-RFQs');
select acs_privilege__add_child('admin', 'view_freelance_rfqs_all');



select im_priv_create('add_freelance_rfqs','P/O Admins');
select im_priv_create('add_freelance_rfqs','Project Managers');
select im_priv_create('add_freelance_rfqs','Senior Managers');
select im_priv_create('add_freelance_rfqs','Sales');
select im_priv_create('add_freelance_rfqs','Accounting');

select im_priv_create('view_freelance_rfqs','P/O Admins');
select im_priv_create('view_freelance_rfqs','Project Managers');
select im_priv_create('view_freelance_rfqs','Senior Managers');
select im_priv_create('view_freelance_rfqs','Sales');
select im_priv_create('view_freelance_rfqs','Accounting');

select im_priv_create('view_freelance_rfqs_all','P/O Admins');
select im_priv_create('view_freelance_rfqs_all','Project Managers');
select im_priv_create('view_freelance_rfqs_all','Senior Managers');
select im_priv_create('view_freelance_rfqs_all','Sales');
select im_priv_create('view_freelance_rfqs_all','Accounting');




-------------------------------------------------------------
-- Freelance RFQ Answer
--
-- This object type represents the answers coming from
-- the freelance vendors. So it contains one row for every
-- rfq participant.

SELECT acs_object_type__create_type (
	'im_freelance_rfq_answer',	-- object_type
	'Freelance RFQ Answer',		-- pretty_name
	'Freelance RFQ Answers',	-- pretty_plural
	'acs_object',			-- supertype
	'im_freelance_rfq_answers',	-- table_name
	'answer_id',			-- id_column
	'im_freelance_rfq_answers',	-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_freelance_rfq_answer__name'	-- name_method
);


create table im_freelance_rfq_answers (
	answer_id		integer
				constraint im_freelance_rfq_answer_id_pk
				primary key
				constraint im_freelance_rfq_answer_id_fk
				references acs_objects,
	answer_user_id		integer
				constraint im_freelance_rfq_answer_user_fk
				references users,
	answer_rfq_id		integer
				constraint im_freelance_rfq_answer_rfq_fk
				references im_freelance_rfqs,
	answer_accepted_p	char(1)
				constraint im_freelance_rfq_answers_accepted_p
				check (answer_accepted_p in ('t','f')),
	answer_status_id	integer
				constraint im_freelance_rfq_answer_status_fk
				references im_categories,
	answer_type_id		integer
				constraint im_freelance_rfq_answer_type_fk
				references im_categories,
	answer_overall_status_id	integer
                                constraint im_freelance_rfq_answer_overall_fk
                                references im_categories,
	answer_start_date	timestamptz,
	answer_end_date		timestamptz,
	answer_note		text,

	-- Detailed Answers (to be extended with DynFields)
	answer_amount		numeric(12,2),
	answer_currency		char(3)
				constraint im_freelance_rfq_answer_price_currency_fk
				references currency_codes(iso)
);

create unique index im_freelance_rfq_answers_un on im_freelance_rfq_answers (answer_user_id, answer_rfq_id);
create index im_freelance_rfq_rfq_idx on im_freelance_rfq_answers (answer_rfq_id);


-- Intranet Freelance RFQ Answer Overall Status

INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (4480,'OK','Intranet Freelance RFQ Overall Status');

INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (4485,'Not OK','Intranet Freelance RFQ Overall Status');

create or replace view im_freelance_rfq_overall_status as
select	category_id as freelance_rfq_overall_status_id,
        category as freelance_rfq_overall_status
from    im_categories
where   category_type = 'Intranet Freelance RFQ Overall Status';



-------------------------------------------------------------
-- Set weights for language criteria


delete from im_categories where category_type = 'Intranet Experience Level';
INSERT INTO im_categories VALUES (2200, 'Unconfirmed','',
'Intranet Experience Level','category','t','f');
INSERT INTO im_categories VALUES (2201, 'Low','',
'Intranet Experience Level','category','t','f');
INSERT INTO im_categories VALUES (2202, 'Medium','',
'Intranet Experience Level','category','t','f');
INSERT INTO im_categories VALUES (2203, 'High','',
'Intranet Experience Level','category','t','f');



-------------------------------------------------------------
-- Creator/Deletor functions


-- Delete a single freelance_rfq_answer (if we know its ID...)
create or replace function im_freelance_rfq_answer__delete (integer)
returns integer as '
DECLARE
	p_freelance_rfq_answer_id		alias for $1;
begin
	-- Erase the im_freelance_rfq_answers entry
	delete from	im_freelance_rfq_answers
	where		answer_id = p_freelance_rfq_answer_id;

	-- Erase the object
	PERFORM acs_object__delete(p_freelance_rfq_answer_id);
	return 0;
end' language 'plpgsql';


create or replace function im_freelance_rfq_answer__name (integer)
returns varchar as '
DECLARE
	p_freelance_rfq_answers_id		alias for $1;
	v_name  varchar(1000);
begin
	select	r.rfq_name 
			|| '' on "'' || p.project_name 
			|| ''" for '' || im_name_from_user_id(a.answer_user_id)
	into	v_name
	from	im_freelance_rfq_answers a,
		im_freelance_rfqs r,
		im_projects p
	where
		a.answer_id = p_freelance_rfq_answers_id
		and a.answer_rfq_id = r.rfq_id
		and r.rfq_project_id = p.project_id
	;

	return v_name;
end;' language 'plpgsql';


create or replace function im_freelance_rfq_answer__new (
	integer, varchar, timestamptz, integer,	varchar, integer, 
	integer, integer, integer, integer
) returns integer as '
declare
	p_freelance_rfq_answer_id	alias for $1;	-- freelance_rfq_answer_id default null
	p_object_type		alias for $2;	-- object_type default ''im_freelance_rfq_answer''
	p_creation_date		alias for $3;	-- creation_date default now()
	p_creation_user		alias for $4;	-- creation_user
	p_creation_ip		alias for $5;	-- creation_ip default null
	p_context_id		alias for $6;	-- context_id default null

	p_user_id		alias for $7;	-- freelance_rfq_answer_name
	p_rfq_id		alias for $8;	-- rfq_id
	p_type_id		alias for $9;	-- type_id
	p_status_id		alias for $10;	-- status_id

	v_answer_id		integer;
    begin
	v_answer_id := acs_object__new (
		p_freelance_rfq_answer_id,	-- cost_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,		-- creation_ip
		p_context_id		-- context_id
	);
--	RAISE NOTICE ''im_freelance_rfq_answer__new:  answer_id=%'', v_answer_id;
	insert into im_freelance_rfq_answers (
		answer_id,
		answer_user_id,
		answer_rfq_id,
		answer_status_id,
		answer_type_id
	) values (
		v_answer_id,
		p_user_id,
		p_rfq_id,
		p_status_id,
		p_type_id
	);

	return v_answer_id;
end;' language 'plpgsql';



-------------------------------------------------------------
-- Create sample DynField for outcomes
--
-- ToDo: Set permissions and Object-Subtype-Map

select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'general_rfq_accept',	-- widget_name
	'#intranet-freelance-rfqs.General_Outcome#',	-- pretty_name
	'#intranet-freelance-rfqs.General_Outcome#',	-- pretty_plural
	10007,			-- storage_type_id
	'string',		-- acs_datatype
	'radio',		-- widget
	'integer',		-- sql_datatype
	'{options { {"#intranet-freelance-rfqs.Yes_I_can_do#" 1} {"#intranet-freelance-rfqs.No_I_decline#" 0} }}'
);



alter table im_freelance_rfqs add general_outcome varchar;

select im_dynfield_attribute__new (
	null,			-- widget_id
	'im_dynfield_attribute', -- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id

	'im_freelance_rfq',	-- attribute_object_type
	'general_outcome',	-- attribute name
	1,
	1,
	null,
	'string',
	'#intranet-freelance-rfqs.General_Outcome#',	-- pretty name
	'#intranet-freelance-rfqs.General_Outcome#',	-- pretty plural
	'general_rfq_accept',
	't',
	't'
);



