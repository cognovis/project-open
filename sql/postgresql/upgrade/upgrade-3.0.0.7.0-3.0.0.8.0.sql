
-- -----------------------------------------------------
-- Add template_p field to indicate templates
-- This field is not being used yet, but good for future
-- versions (3.1)

alter table im_projects add
        template_p              char(1)
                                constraint im_project_template_p
                                check (requires_report_p in ('t','f'))
;

-- add the default 't' value
alter table im_projects 
alter column template_p 
set default 't'
;



-- -----------------------------------------------------
-- Add privileges for budget and budget_hours
--
select acs_privilege__create_privilege('add_budget','Add Budget','Add Budget');
select acs_privilege__add_child('admin', 'add_budget');
select acs_privilege__create_privilege('view_budget','View Budget','View Budget');
select acs_privilege__add_child('admin', 'view_budget');

select acs_privilege__create_privilege('add_budget_hours','Add Budget Hours','Add Budget Hours');
select acs_privilege__add_child('admin', 'add_budget_hours');
select acs_privilege__create_privilege('view_budget_hours','View Budget Hours','View Budget Hours');
select acs_privilege__add_child('admin', 'view_budget_hours');


-- Set preliminary privileges to setup the 
-- permission matrix

select im_priv_create('view_budget','Accounting');
select im_priv_create('view_budget','P/O Admins');
select im_priv_create('view_budget','Project Managers');
select im_priv_create('view_budget','Senior Managers');

select im_priv_create('add_budget','Accounting');
select im_priv_create('add_budget','P/O Admins');
select im_priv_create('add_budget','Senior Managers');


select im_priv_create('view_budget_hours','Employees');
select im_priv_create('view_budget_hours','Accounting');
select im_priv_create('view_budget_hours','P/O Admins');
select im_priv_create('view_budget_hours','Project Managers');
select im_priv_create('view_budget_hours','Senior Managers');

select im_priv_create('add_budget_hours','Accounting');
select im_priv_create('add_budget_hours','P/O Admins');
select im_priv_create('add_budget_hours','Senior Managers');




--
delete from im_view_columns where column_id >= 2000 and column_id < 2099;
--

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2000,20,NULL,'Ok',
'<center>[im_project_on_track_bb $on_track_status_id]</center>',
'','',0,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2002,20,NULL,'Per',
'[im_date_format_locale $percent_completed 2 1] %','','',2,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2005,20,NULL,'Project nr',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_nr</A>"',
'','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2010,20,NULL,'Project Name',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_name</A>"','','',10,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2015,20,NULL,'Client',
'"<A HREF=/intranet/companies/view?company_id=$company_id>$company_name</A>"',
'','',15,'im_permission $user_id view_companies');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2020,20,NULL,'Type',
'$project_type','','',20,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2025,20,NULL,'Project Manager',
'"<A HREF=/intranet/users/view?user_id=$project_lead_id>$lead_name</A>"',
'','',25,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2030,20,NULL,'Start Date',
'$start_date_formatted','','',30,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2035,20,NULL,'Delivery Date',
'$end_date_formatted','','',35,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2040,20,NULL,'Status',
'$project_status','','',40,'');




-- -----------------------------------------------------
-- Add fields for invoicing automation

-- Default value for VAT
alter table im_companies add
        vat                     numeric(12,1)
;

alter table im_companies
alter column vat
set default 0
;


-- Default invoice template

alter table im_companies add
        invoice_template_id     integer
                                constraint im_companies_invoice_template_fk
                                references im_categories
;


-- Default payment method
alter table im_companies add
        payment_method_id       integer
                                constraint im_companies_invoice_payment_fk
                                references im_categories
;

alter table im_companies add
        payment_days            integer
;


-- -----------------------------------------------------
-- Add DynField "im_companies" extension table (if it 
-- doesn't exist already)

create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*)
        into v_count
        from acs_object_type_tables
        where   lower(table_name) = ''im_companies'';

        if v_count > 0 then
            return 0;
        end if;

	insert into acs_object_type_tables (
		object_type, table_name, id_column
	) values (
		''im_company'', ''im_companies'', ''company_id''
	);
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

