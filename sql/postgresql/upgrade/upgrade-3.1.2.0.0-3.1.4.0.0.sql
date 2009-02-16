-- upgrade-3.1.2.0.0-3.1.4.0.0.sql

SELECT acs_log__debug('/packages/intranet-search-pg/sql/postgresql/upgrade/upgrade-3.1.2.0.0-3.1.4.0.0.sql','');


-----------------------------------------------------------
-- invoices & costs(?)

-- We are going for Invoice instead of im_costs, because of
-- performance reasons. There many be many cost items, but
-- they don't usually interest us very much.



create or replace function inline_0 ()
returns integer as '
declare
	v_count			integer;
begin
	select	count(*) into v_count from im_search_object_types
	where	object_type = ''im_invoice'';
	IF v_count > 0 THEN return 0; END IF;

	insert into im_search_object_types values (4,''im_invoice'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0();




create or replace function im_invoice_tsearch ()
returns trigger as '
declare
	v_string	varchar;
begin
	select  coalesce(i.invoice_nr, '''') || '' '' ||
		coalesce(c.cost_nr, '''') || '' '' ||
		coalesce(c.cost_name, '''') || '' '' ||
		coalesce(c.description, '''') || '' '' ||
		coalesce(c.note, '''')
	into
		v_string
	from
		im_invoices i,
		im_costs c
	where	
		i.invoice_id = c.cost_id
		and i.invoice_id = new.invoice_id;

	perform im_search_update(new.invoice_id, ''im_invoice'', new.invoice_id, v_string);
	return new;
end;' language 'plpgsql';




create or replace function inline_0 ()
returns integer as '
declare
	v_count			integer;
begin
	select count(*) into v_count from pg_trigger 
	where lower(tgname) = ''im_invoices_tsearch_tr'';
	IF v_count > 0 THEN return 0; END IF;

	CREATE TRIGGER im_invoices_tsearch_tr
	BEFORE INSERT or UPDATE
	ON im_invoices
	FOR EACH ROW
	EXECUTE PROCEDURE im_invoice_tsearch();

	-- Update all invoices
	update im_invoices set invoice_nr = invoice_nr;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0();



-----------------------------------------------------------
-- Updated project function with translation fields
-- (hard coded, no DynField yet)

create or replace function im_projects_tsearch ()
returns trigger as '
declare
        v_string        varchar;
        v_string2        varchar;
begin
        select  coalesce(project_name, '''') || '' '' ||
                coalesce(project_nr, '''') || '' '' ||
                coalesce(project_path, '''') || '' '' ||
                coalesce(description, '''') || '' '' ||
                coalesce(note, '''')
        into    v_string
        from    im_projects
        where   project_id = new.project_id;

        v_string2 := '''';
        if column_exists(''im_projects'', ''company_project_nr'') then

                select  coalesce(company_project_nr, '''') || '' '' ||
                        coalesce(final_company, '''')
                into    v_string2
                from    im_projects
                where   project_id = new.project_id;

                v_string := v_string || '' '' || v_string2;

        end if;

        perform im_search_update(new.project_id, ''im_project'', new.project_id, v_string);

        return new;
end;' language 'plpgsql';

