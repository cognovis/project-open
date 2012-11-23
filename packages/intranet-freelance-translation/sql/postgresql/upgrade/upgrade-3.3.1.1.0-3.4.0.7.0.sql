-- upgrade-3.3.1.1.0-3.4.0.7.0.sql
SELECT acs_log__debug('/packages/intranet-freelance-translation/sql/postgresql/upgrade/upgrade-3.3.1.1.0-3.4.0.7.0.sql','');


-- Has user worked for company ?
--
create or replace function im_user_worked_for_company ( integer, integer )
returns integer as '

DECLARE
        v_user_id            alias for $1;
        v_company_id         alias for $2;
        v_count              integer;
BEGIN
        select
                count(*)
        into
                v_count
        from
                (
                select
                        p.project_id
                from
                        acs_rels r,
                        im_projects p
                where
                        p.company_id = v_company_id
                        and r.object_id_one = p.project_id
                        and object_id_two = v_user_id
                ) t;

        return v_count;
end;' language 'plpgsql';