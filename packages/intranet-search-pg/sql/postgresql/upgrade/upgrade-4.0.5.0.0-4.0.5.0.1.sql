-- upgrade-4.0.5.0.0-4.0.5.0.1.sql

SELECT acs_log__debug('/packages/intranet-search-pg/sql/postgresql/upgrade/upgrade-4.0.5.0.0-4.0.5.0.1.sql','');


create or replace function norm_text (varchar)
returns varchar as '
declare
        p_str   alias for $1;
        v_str   varchar;
begin
        select translate(p_str, ''@.-_'', ''    '')
        into v_str;

        return norm_text_utf8(v_str);
end;' language 'plpgsql';

update persons set first_names = first_names;
update im_projects set project_nr = project_nr;

