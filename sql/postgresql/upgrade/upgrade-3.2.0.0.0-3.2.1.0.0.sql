-- upgrade-3.2.0.0.0-3.2.1.0.0.sql


-----------------------------------------------------------
-- Copy 'Intranet Project Type' Category into the range
-- of 4000-4099
-----------------------------------------------------------

-- 2006-05-28: Not possible: The static WF uses the hard
-- coded Intranet Project Type values...

-- Set the counter for the next categories to above the fixed
-- category range.


-----------------------------------------------------------
-- Add a "tm_type_id" field to im_trans_tasks and 
-- define categories

-- 4100-4199    Intranet Trans TM Type


create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select  count(*)
        into    v_count
        from    im_categories
        where   category_id = 4200;

        if v_count = 1 then
            return 0;
        end if;

	INSERT INTO im_categories (category_id, category, category_type, category_description) VALUES
	(4200,'External', 'Intranet TM Integration Type','Trados is integrated by up/downloading files');
	INSERT INTO im_categories (category_id, category, category_type, category_description) VALUES
	(4202,'Ophelia', 'Intranet TM Integration Type','Ophelia in integrated via UserExists');
	INSERT INTO im_categories (category_id, category, category_type, category_description) VALUES
	(4204,'None', 'Intranet TM Integration Type','No integration - not a TM task');

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



alter table im_trans_tasks
add tm_integration_type_id integer references im_categories;

-- No default - default should be handled by TCL
-- alter table im_trans_tasks alter column tm_type_id 
-- set default 4100;









