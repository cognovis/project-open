-- upgrade-0.5d5-0.5d6.sql

SELECT acs_log__debug('/packages/intranet-cognovis/sql/postgresql/upgrade/upgrade-0.5d5-0.5d6.sql','');

-- User Localization Component
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'User Locale',
       'intranet-core',
       'left',
       '/intranet/users/view',
       null,
       0,
       'im_user_localization_component $user_id $return_url');

-- Make sure User Locale Component is readable for anybody
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	row		RECORD;
	v_object_id	INTEGER;

BEGIN

 	SELECT o.object_id INTO v_object_id 
	FROM im_component_plugins c, acs_objects o
	WHERE o.object_id = c.plugin_id
	AND package_name = ''intranet-core''
	AND plugin_name = ''User Locale'';

	FOR row IN 
		SELECT DISTINCT g.group_id
		FROM acs_objects o, groups g, im_profiles p
		WHERE g.group_id = o.object_id
		AND g.group_id = p.profile_id
		AND o.object_type = ''im_profile''
	LOOP
	
		PERFORM im_grant_permission(v_object_id,row.group_id,''read'');

	END LOOP;

	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();