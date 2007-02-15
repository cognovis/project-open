-- upgrade-3.2.6.0.0-3.2.7.0.0.sql


-------------------------------------------------------------
-- Slow query for Employees (the most frequent one...)
-- because of missing outer-join reordering in PG 7.4...
-- Now adding the "im_employees" (in extra-from/extra-where)
-- INSIDE the basic query.

update im_view_columns set extra_from = null, extra_where = null where column_id = 5500;




-------------------------------------------------------------
-- Allow to make quotes for both active and potential companies



create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from im_categories
	where category = ''Active or Potential'';
        IF 0 != v_count THEN return 0; END IF;

	insert into im_categories (
	        CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID,
	        CATEGORY, CATEGORY_TYPE
	) values (
	        '''', ''f'', ''40'',
	        ''Active or Potential'', ''Intranet Company Status''
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

	return 1;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




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
-- select im_profiles_from_user_id(624);






create or replace function im_name_from_id(integer)
returns varchar as '
DECLARE
        v_integer       alias for $1;
        v_result        varchar(4000);
BEGIN
        -- Try with category - probably the fastest
        select category
        into v_result
        from im_categories
        where category_id = v_integer;

        IF v_result is not null THEN return v_result; END IF;

        -- Try with ACS_OBJECT
        select acs_object__name(v_integer)
        into v_result;

        return v_result;

END;' language 'plpgsql';


create or replace function im_name_from_id(varchar)
returns varchar as '
DECLARE
        v_result	alias for $1;
BEGIN
        return v_result;
END;' language 'plpgsql';



create or replace function im_name_from_id(timestamptz)
returns varchar as '
DECLARE
        v_timestamp	alias for $1;
BEGIN
        return to_char(v_timestamp, ''YYYY-MM-DD'');
END;' language 'plpgsql';



create or replace function im_name_from_id(numeric)
returns varchar as '
DECLARE
        v_result        alias for $1;
BEGIN
        return v_result::varchar;
END;' language 'plpgsql';

