-- upgrade-3.2.6.0.0-3.2.7.0.0.sql


-------------------------------------------------------------
-- Allow to make quotes for both active and potential companies


insert into im_categories (
        CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID,
        CATEGORY, CATEGORY_TYPE
) values (
        '', 'f', '40',
        'Active or Potential', 'Intranet Company Status'
);

-- Introduce "Active or Potential" as supertype of both
-- "Acative" and "Potential"
--
-- im_category_hierarchy(parent, child)

INSERT INTO im_category_hierarchy 
	SELECT 40, child_id
	FROM im_category_hierarchy
	WHERE parent_id = 41
;

-- Make "Potential" and "Active" themselves children of "Act or Pot"
INSERT INTO im_category_hierarchy VALUES (40, 41);
INSERT INTO im_category_hierarchy VALUES (40, 46);



-- Return a string with all profiles of the user
create or replace function im_profiles_from_user_id(integer)
returns varchar as '
DECLARE
        v_user_id       alias for $1;
        v_profiles      varchar;
        row             RECORD;
BEGIN
        v_profiles := '''';
        FOR row IN
                select  group_name
                from    groups g,
                        im_profiles p,
                        group_distinct_member_map m
                where   m.member_id = v_user_id
                        and g.group_id = m.group_id
                        and g.group_id = p.profile_id
        LOOP
            IF '''' != v_profiles THEN v_profiles := v_profiles || '', ''; END IF;
            v_profiles := v_profiles || row.group_name;
        END LOOP;

        return v_profiles;
END;' language 'plpgsql';
select im_profiles_from_user_id(624);


