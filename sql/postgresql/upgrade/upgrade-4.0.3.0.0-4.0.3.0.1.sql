-- upgrade-4.0.3.0.0-4.0.3.0.1.sql

SELECT acs_log__debug('/packages/intranet-portfolio-management/sql/postgresql/upgrade/upgrade-4.0.3.0.0-4.0.3.0.1.sql','');

create or replace function inline_1 ()
returns integer as '
declare
        v_menu			integer;
        v_parent_menu           integer;
        v_senior_managers       integer;
begin

	select menu_id into v_parent_menu from im_menus where label = ''main'';
	select group_id into v_senior_managers from groups where group_name = ''Senior Managers''; 

        v_menu := im_menu__new (
                null,                                   -- p_menu_id
                ''im_menu'',                            -- object_type
                now(),                                  -- creation_date
                null,                                   -- creation_user
                null,                                   -- creation_ip
                null,                                   -- context_id
                ''intranet-portfolio-management'',	-- package_name
                ''project_programs'',			-- label
                ''Programs'', 				-- name
                ''/intranet-portfolio-management/index'',   -- url
                35,                                     -- sort_order
                v_parent_menu,				-- parent_menu_id
                null                                    -- p_visible_tcl
        );
 
        PERFORM acs_permission__grant_permission(v_menu, v_senior_managers, ''read'');
        return 0;

end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();


-- Change existing view 
CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS INTEGER AS $body$
DECLARE
        v_count                 INTEGER;
BEGIN

	-- Simple verification if records exists and needs to be updated 
	select count(*) into v_count from im_view_columns where column_id = 30010 and column_name = 'Project Name';
		
	IF v_count = 1 THEN
		BEGIN
			update 
			      im_view_columns 
			set 
			      column_name = 'Program Name',
			      column_render_tcl = '"<A HREF=/intranet/projects/index?&filter_advanced_p=1&program_id=$project_id>[string range $project_name 0 30]</A>"'
                	where 
			      column_id = 30010;  
	       EXCEPTION
			WHEN OTHERS THEN 
			RAISE NOTICE 'Unable change view column attributes for column_id: 30010';
			RETURN 0;
               END;
	END IF;
        RETURN 0;
 
END;$body$ LANGUAGE 'plpgsql';
select inline_0 ();
drop function inline_0();
