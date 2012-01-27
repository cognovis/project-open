-- upgrade-4.0.0.0.1-4.0.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-4.0.0.0.1-4.0.0.0.1.sql','');

-- Create indices on type and status to speedup queries

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin

		select count(*) into v_count 
		from pg_indexes 
		where tablename = ''im_tickets'' and indexname = ''im_ticket_type_id_idx'';

        IF v_count > 0 THEN return 1; END IF;

		create index im_ticket_type_id_idx on im_tickets(ticket_type_id);

        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin

        select count(*) into v_count
        from pg_indexes
        where tablename = ''im_tickets'' and indexname = ''im_ticket_status_id_idx'';

        IF v_count > 0 THEN return 1; END IF;

		create index im_ticket_status_id_idx on im_tickets(ticket_status_id);

        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();








