

-- Remove components from packages intranet-trans* 
CREATE OR REPLACE FUNCTION inline_0 () 
RETURNS integer AS '
DECLARE
	row		record;

BEGIN
	FOR row IN
	SELECT plugin_id FROM im_component_plugins WHERE package_name = ''intranet-intranet-trans-project-wizard''
	LOOP
		PERFORM im_component_plugin__delete(row.plugin_id);
	END LOOP;
	
	RETURN 0;
END;' language 'plpgsql';

--SELECT inline_0 ();
DROP FUNCTION inline_0 ();




CREATE OR REPLACE FUNCTION inline_0 (integer)
RETURNS integer AS '
declare
  remove_user__user_id                alias for $1;  
  v_rec           record;
  v_row_revs	  record;

begin
    delete
    from acs_permissions
    where grantee_id = remove_user__user_id;

    FOR v_row_revs IN
    	SELECT object_id FROM acs_objects
	WHERE creation_user = remove_user__user_id
    LOOP
	PERFORM content_revision__delete(v_row_revs.object_id);
    END LOOP;


    for v_rec in select rel_id
                 from acs_rels
                 where object_id_two = remove_user__user_id
    loop
        perform acs_rel__delete(v_rec.rel_id);
    end loop;

    perform acs_user__delete(remove_user__user_id);

    return 0; 
end;' language 'plpgsql';

SELECT inline_0 (11180);
DROP FUNCTION inline_0 (integer);