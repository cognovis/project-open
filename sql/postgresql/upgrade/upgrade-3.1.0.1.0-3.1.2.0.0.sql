

create or replace function acs_privilege__create_privilege (varchar,varchar,varchar)
returns integer as '
declare
	create_privilege__privilege		alias for $1;
	create_privilege__pretty_name		alias for $2;	-- default null
	create_privilege__pretty_plural		alias for $3;	-- default null
	v_count					integer;
BEGIN
	SELECT count(*) into v_count from acs_privileges
	WHERE privilege = create_privilege__privilege;
	if v_count > 0 then return 0; end if;
	
	INSERT into acs_privileges (privilege, pretty_name, pretty_plural)
	VALUES (create_privilege__privilege, create_privilege__pretty_name, create_privilege__pretty_plural);

	return 0;
END;' language 'plpgsql';


create or replace function acs_privilege__add_child (varchar,varchar)
returns integer as '
declare
	add_child__privilege		alias for $1;
	add_child__child_privilege	alias for $2;
	v_count				integer;
BEGIN
	SELECT count(*) into v_count from acs_privilege_hierarchy
	WHERE privilege = add_child__privilege and child_privilege = add_child__child_privilege;
	IF v_count > 0 THEN return 0; END IF;

	insert into acs_privilege_hierarchy (privilege, child_privilege)
	values (add_child__privilege, add_child__child_privilege);

	return 0; 
END;' language 'plpgsql';


-- Add a privilege to allow all users to edit projects
--
select acs_privilege__create_privilege('edit_projects_all','Edit All Projects','Edit All Projects');
select acs_privilege__add_child('admin', 'edit_projects_all');


-- -----------------------------------------------------
-- Add company_contact_id to im_projects 
-- if it doesnt exist yet

create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*)	into v_count from user_tab_columns
	where upper(table_name) = upper(''im_projects'') and upper(column_name) = upper(''company_contact_id'');
	if v_count > 0 then return 0; end if;

	alter table im_projects 
	add company_contact_id integer;

	alter table im_projects 
	add FOREIGN KEY (company_contact_id) 
	references users;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
