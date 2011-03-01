-- upgrade-3.4.0.2.0-3.4.0.2.1.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-invoices/sql/postgresql/upgrade/upgrade-3.4.0.2.0-3.4.0.2.1.sql','');


-- references task_id's to invoice items
--

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin
        select count(*) into v_count from user_tab_columns
        where lower(table_name) = ''im_invoice_items'' and lower(column_name) = ''task_id'';
        IF v_count > 0 THEN return 1; END IF;

        alter table im_invoice_items add column task_id integer;
        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

SELECT im_lang_add_message('en_US','intranet-timesheet2-invoices','No_Information','No information about task available, pls. try other view');