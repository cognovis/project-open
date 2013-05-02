-- upgrade-4.0.3.5.4-4.0.3.5.5.sql
SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.3.5.4-4.0.3.5.5.sql','');


create or replace function inline_0() returns varchar as $body$
        DECLARE
                v_count         integer;
        BEGIN
                select count(*) into v_count from user_tab_columns
		where lower(table_name) = 'im_projects' and lower(column_name) = 'company_contact_id';
                IF v_count > 0 THEN return 1; END IF;

		alter table im_projects add column company_contact_id integer
		constraint im_project_company_contact_fk references persons;
                return 0;
        END;
$body$ language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

