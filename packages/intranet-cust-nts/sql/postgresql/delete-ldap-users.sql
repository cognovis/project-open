CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
	row2                    record;
BEGIN
	FOR row IN 
SELECT user_id from users where user_id not in (select employee_id from im_employees) and user_id not in (select object_id_one from acs_rels)
	LOOP
          for row2 in 
            select rel_id from acs_rels where object_id_two = row.user_id limit 1
          loop
	delete from group_element_index where rel_id = row2.rel_id;
	delete from membership_rels where rel_id = row2.rel_id;
	delete from acs_rels where rel_id = row2.rel_id;
          end loop;
                perform person__delete(row.user_id);
	END LOOP;

	RETURN 0;
END;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
