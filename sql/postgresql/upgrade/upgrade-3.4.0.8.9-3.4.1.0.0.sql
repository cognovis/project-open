-- upgrade-3.4.0.8.9-3.4.1.0.0.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.8.9-3.4.1.0.0.sql','');


-- Add a l10n message
SELECT im_lang_add_message('en_US','intranet-core','Category_Type','Category Type');



-- Introduce default_tax field
create or replace function inline_0 ()
returns integer as '
DECLARE
        v_count                 integer;
BEGIN
        select count(*) into v_count from user_tab_columns
        where  lower(table_name) = ''im_companies'' and lower(column_name) = ''default_tax'';
        IF v_count > 0 THEN return 0; END IF;

	alter table im_companies add default_tax numeric(12,1);
	alter table im_companies alter column default_tax set default 0;

        return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();

