
-- Some helper functions to make our queries easier to read
create or replace function im_project_name_from_id (integer)
returns varchar as '
DECLARE
        p_project_id	alias for $1;
        v_project_name	varchar(50);
BEGIN
        select project_name
        into v_project_name
        from im_projects
        where project_id = p_project_id;

        return v_project_name;
end;' language 'plpgsql';

