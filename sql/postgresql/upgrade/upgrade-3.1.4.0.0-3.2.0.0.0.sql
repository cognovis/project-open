-- upgrade-3.1.4.0.0-3.2.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-search-pg/sql/postgresql/upgrade/upgrade-3.1.4.0.0-3.2.0.0.0.sql','');


-----------------------------------------------------------
-- How has this ever worked out???
-- There was a "and object_type_id = v_object_type_id missing,
-- so that there could be duplicate objects int he im_search_objects
-- table
-----------------------------------------------------------

create or replace function im_search_update (integer, varchar, integer, varchar)
returns integer as '
declare
        p_object_id     alias for $1;
        p_object_type   alias for $2;
        p_biz_object_id alias for $3;
        p_text          alias for $4;

        v_object_type_id        integer;
        v_exists_p              integer;
begin
        select  object_type_id
        into    v_object_type_id
        from    im_search_object_types
        where   object_type = p_object_type;

        select  count(*)
        into    v_exists_p
        from    im_search_objects
        where   object_id = p_object_id
                and object_type_id = v_object_type_id;

        if v_exists_p = 1 then
                update im_search_objects set
                        object_type_id  = v_object_type_id,
                        biz_object_id   = p_biz_object_id,
                        fti             = to_tsvector(''default'', norm_text(p_text))
                where
                        object_id       = p_object_id
                        and object_type_id = v_object_type_id;
        else
                insert into im_search_objects (
                        object_id,
                        object_type_id,
                        biz_object_id,
                        fti
                ) values (
                        p_object_id,
                        v_object_type_id,
                        p_biz_object_id,
                        to_tsvector(''default'', p_text)
                );
        end if;

        return 0;
end;' language 'plpgsql';

