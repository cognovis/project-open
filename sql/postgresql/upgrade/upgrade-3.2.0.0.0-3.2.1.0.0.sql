-------------------------------------------------------------
-- upgrade-3.2.0.0.0-3.2.1.0.0.sql
-------------------------------------------------------------



-------------------------------------------------------------
-- Portrait Fields
--
alter table persons add portrait_checkdate date;
alter table persons add portrait_file varchar(400);


-- Helper functions to make our queries easier to read
-- and to avoid outer joins with parent projects etc.
create or replace function im_project_name_from_id (integer)
returns varchar as '
DECLARE
        p_project_id    alias for $1;
        v_project_name  varchar(1000);
BEGIN
        select project_name
        into v_project_name
        from im_projects
        where project_id = p_project_id;

        return v_project_name;
end;' language 'plpgsql';


-------------------------------------------------------------
-- Extend im_categories with "aux" fields

alter table im_categories add
aux_int1 integer;

alter table im_categories add
aux_int2 integer;

alter table im_categories add
aux_string1 varchar(1000);

alter table im_categories add
aux_string2 varchar(1000);

update im_categories
set aux_string1 = category_description;



-- -----------------------------------------------------
-- Add a customer_project_nr if not already there...


create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select  count(*)
        into    v_count
        from    user_tab_columns
        where   lower(table_name) = ''im_projects''
		and lower(column_name) = ''company_project_nr'';

        if v_count = 1 then
            return 0;
        end if;

        alter table im_projects
        add company_project_nr varchar(200);

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





-- -----------------------------------------------------
-- Add company_contact_id to im_projects
-- if it doesnt exist yet

create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select  count(*)
        into    v_count
        from    user_tab_columns
        where   upper(table_name) = upper(''im_projects'')
                and upper(column_name) = upper(''company_contact_id'');

        if v_count > 0 then
            return 0;
        end if;

        alter table im_projects
        add company_contact_id integer;

        alter table im_projects
        add FOREIGN KEY (company_contact_id)
        references users;

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select  count(*)
        into    v_count
        from    user_tab_columns
        where   lower(table_name) = ''im_projects''
		and lower(column_name) = ''final_company'';

        if v_count = 1 then
            return 0;
        end if;

        alter table im_projects
        add final_company varchar(200);

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




