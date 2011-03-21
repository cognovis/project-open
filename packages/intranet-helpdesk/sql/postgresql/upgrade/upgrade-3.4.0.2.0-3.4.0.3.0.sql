-- upgrade-3.4.0.2.0-3.4.0.3.0.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-3.4.0.2.0-3.4.0.3.0.sql','');

-- Creation Date
create or replace function inline_0 ()
returns integer as '
declare
	v_count	integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_tickets'' and
		lower(column_name) = ''ticket_creation_date'';
	IF 0 != v_count THEN return 0; END IF;

	alter table im_tickets add
	ticket_creation_date timestamptz;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-- First human reaction from provider side
create or replace function inline_0 ()
returns integer as '
declare
	v_count	integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_tickets'' and
		lower(column_name) = ''ticket_reaction_date'';
	IF 0 != v_count THEN return 0; END IF;

	alter table im_tickets add
	ticket_reaction_date timestamptz;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- Confirmation that this is an issue
create or replace function inline_0 ()
returns integer as '
declare
	v_count	integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_tickets'' and
		lower(column_name) = ''ticket_confirmation_date'';
	IF 0 != v_count THEN return 0; END IF;

	alter table im_tickets add
	ticket_confirmation_date timestamptz;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- Provider says ticket is done
create or replace function inline_0 ()
returns integer as '
declare
	v_count	integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_tickets'' and
		lower(column_name) = ''ticket_done_date'';
	IF 0 != v_count THEN return 0; END IF;

	alter table im_tickets add
	ticket_done_date timestamptz;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- Customer confirms ticket is done
create or replace function inline_0 ()
returns integer as '
declare
	v_count	integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = ''im_tickets'' and
		lower(column_name) = ''ticket_signoff_date'';
	IF 0 != v_count THEN return 0; END IF;

	alter table im_tickets add
	ticket_signoff_date timestamptz;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



