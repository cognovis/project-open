-- upgrade-3.4.0.6.0-3.4.0.6.1.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.6.0-3.4.0.6.1.sql','');


update im_menus set
	menu_gif_small = 'arrow_right'
where
	parent_menu_id in (
		select	menu_id
		from	im_menus
		where	label = 'admin'
	)
;



create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_timesheet_task'' and table_name = ''im_projects'';
	IF v_count > 0 THEN RETURN 1; END IF;

	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_timesheet_task'', ''im_projects'', ''project_id'');

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_timesheet_conf_object'' and table_name = ''im_timesheet_conf_objects'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_timesheet_conf_object'', ''im_timesheet_conf_objects'', ''conf_id'');
	

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_dynfield_attribute'' and table_name = ''im_dynfield_attributes'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_dynfield_attribute'', ''im_dynfield_attributes'', ''attribute_id'');
	

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_forum_topic'' and table_name = ''im_forum_topics'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_forum_topic'', ''im_forum_topics'', ''topic_id'');
	

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_invoice'' and table_name = ''im_costs'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_invoice'', ''im_costs'', ''cost_id'');
	

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_timesheet_invoice'' and table_name = ''im_invoices'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_timesheet_invoice'', ''im_invoices'', ''invoice_id'');

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_timesheet_invoice'' and table_name = ''im_costs'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_timesheet_invoice'', ''im_costs'', ''cost_id'');
	

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_trans_invoice'' and table_name = ''im_invoices'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_trans_invoice'', ''im_invoices'', ''invoice_id'');

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_trans_invoice'' and table_name = ''im_costs'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_trans_invoice'', ''im_costs'', ''cost_id'');
	

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_gantt_project'' and table_name = ''im_gantt_projects'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_gantt_project'', ''im_gantt_projects'', ''project_id'');

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_gantt_project'' and table_name = ''im_projects'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_gantt_project'', ''im_projects'', ''project_id'');
	

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



delete from im_biz_object_urls where object_type = 'im_gantt_project';
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_gantt_project','view','/intranet/projects/view?project_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_gantt_project','edit','/intranet/projects/new?project_id=');



create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_ticket'' and table_name = ''im_projects'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_ticket'', ''im_projects'', ''project_id'');
	

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_indicator'' and table_name = ''im_indicators'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_indicator'', ''im_indicators'', ''indicator_id'');

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_indicator'' and table_name = ''im_reports'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_indicator'', ''im_reports'', ''report_id'');
	

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_cost_center'' and table_name = ''im_cost_centers'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_cost_center'', ''im_cost_centers'', ''cost_center_id'');
	

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_cost'' and table_name = ''im_costs'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_cost'', ''im_costs'', ''cost_id'');
	

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_repeating_cost'' and table_name = ''im_repeating_costs'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_repeating_cost'', ''im_repeating_costs'', ''rep_cost_id'');

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_cost'' and table_name = ''im_costs'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_cost'', ''im_costs'', ''cost_id'');
	

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_investment'' and table_name = ''im_investments'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_investment'', ''im_investments'', ''investment_id'');

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_investment'' and table_name = ''im_repeating_costs'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_investment'', ''im_repeating_costs'', ''rep_cost_id'');

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where object_type = ''im_investment'' and table_name = ''im_costs'';
	IF v_count > 0 THEN RETURN 1; END IF;
	
	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_investment'', ''im_costs'', ''cost_id'');
	
	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

	