---------------------------------------------------------
-- Modified tree_ancestor_key function that returns the
-- next highest ancestor if the ancestor at the given
-- level doesnt exist (we are looking for a subproject,
-- but there is only a main project).

create or replace function im_reporting_cube_tree_ancestor_key(varbit, integer) returns varbit as '
declare
        p_tree_key              alias for $1;
        p_level                 alias for $2;

        v_level                 integer default 0;
        v_pos                   integer default 1;
begin
        if tree_level(p_tree_key) < p_level then
                -- go up one level instead or reporting an error
                return im_reporting_cube_tree_ancestor_key(p_tree_key, p_level -1);
        end if;

        while v_level < p_level loop
                v_level := v_level + 1;
                if substring(p_tree_key, v_pos, 1) = ''1'' then
                        v_pos := v_pos + 32;
                else
                        v_pos := v_pos + 8;
                end if;
        end loop;
        return substring(p_tree_key, 1, v_pos - 1);
end;' language 'plpgsql' immutable strict;

