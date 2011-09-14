-- /packages/intranet-funambol/sql/postgresql/intranet-funambol-drop.sql
--
-- Copyright (c) 2003-2010 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


---------------------------------------------------------------------
-- Changes to the Funambol data model
---------------------------------------------------------------------

create or replace function inline_0 ()
returns integer as $$
DECLARE
	v_count		integer;
BEGIN
    SELECT count(*) INTO v_count FROM user_tab_columns
    WHERE lower(table_name) = 'fnbl_user' AND lower(column_name) = 'po_id';
    IF v_count = 1 THEN
	ALTER TABLE fnbl_user DROP COLUMN po_id;
    END IF;

    SELECT count(*) INTO v_count FROM user_tab_columns
    WHERE lower(table_name) = 'fnbl_pim_calendar' AND lower(column_name) = 'po_id';
    IF v_count = 1 THEN
	ALTER TABLE fnbl_pim_calendar DROP COLUMN po_id;
    END IF;

    RETURN 0;
END;$$ language 'plpgsql';
select inline_0();
drop function inline_0();

drop function fnbl_next_id (varchar);
drop function fnbl_to_po_task_status (integer);
drop function fnbl_from_po_task_status (integer);
drop function fnbl_export_user_accounts ();
drop function fnbl_export_tickets (integer);
drop function fnbl_sync ();

