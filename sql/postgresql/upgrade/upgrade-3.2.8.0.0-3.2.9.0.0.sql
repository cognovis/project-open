-- upgrade-3.2.8.0.0-3.2.9.0.0.sql


alter table persons add demo_group varchar(50);
alter table persons add demo_password varchar(50);





-------------------------------------------------------------
-- Slow query for Employees (the most frequent one...)
-- because of missing outer-join reordering in PG 7.4...
-- Now adding the "im_employees" (in extra-from/extra-where)
-- INSIDE the basic query.

update im_view_columns set extra_from = null, extra_where = null where column_id = 5500;







create or replace function im_priv_create (varchar, varchar)
returns integer as '
DECLARE
        p_priv_name     alias for $1;
        p_profile_name  alias for $2;

        v_profile_id            integer;
        v_object_id             integer;
        v_count                 integer;
BEGIN
     -- Get the group_id from group_name
     select group_id
     into v_profile_id
     from groups
     where group_name = p_profile_name;

     -- Get the Main Site id, used as the global identified for permissions
     select package_id
     into v_object_id
     from apm_packages
     where package_key=''acs-subsite'';


     select count(*) into v_count
     from acs_permissions
     where object_id = v_object_id
        and grantee_id = v_profile_id
        and privilege = p_priv_name;

     IF 0 = v_count THEN
        PERFORM acs_permission__grant_permission(v_object_id, v_profile_id, p_priv_name);
     END IF;

     return 0;

end;' language 'plpgsql';


