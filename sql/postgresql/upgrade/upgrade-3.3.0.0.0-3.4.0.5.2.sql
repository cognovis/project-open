-- upgrade-3.3.3.0.0-3.4.0.5.2.sql

SELECT acs_log__debug('/packages/intranet-search-pg/sql/postgresql/upgrade/upgrade-3.3.0.0.0-3.4.0.5.2.sql','');


create or replace function inline_0 ()
returns integer as '
declare
        v_count          integer;
begin
        select  count(*) into v_count from user_tab_columns
        where   lower(table_name) = ''im_search_objects''
                and lower(column_name) = ''fti'';
        if v_count = 1 then return 0;end if;

        alter table im_search_objects add fti tsvector;
	create index im_search_objects_fti_idx on im_search_objects using gist(fti);

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
