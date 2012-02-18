-- /packages/intranet-xowiki/sql/postgresql/intranet-xowiki-create.sql

-- Xowiki View Component                                                                                                                              
SELECT im_component_plugin__new (
       null, 
       'acs_object', 
       now(), 
       null, 
       null, 
       null, 
       'Xowiki View Cognovis', 
       'intranet-xowiki', 
       'left', 
       '/intranet/projects/view', 
       null, 
       110, 
       'im_xowiki_view_component -object_id $project_id -return_url $return_url'
);

-- Weblog Component                                                                                                                              
SELECT im_component_plugin__new (
       null, 
       'acs_object', 
       now(), 
       null, 
       null, 
       null, 
       'Project Weblog Component', 
       'intranet-xowiki', 
       'left', 
       '/intranet/projects/view', 
       null, 
       120, 
       'im_xowiki_weblog_component -object_id $project_id -return_url $return_url'
);



alter table cr_text disable trigger cr_text_tr;                                     

delete from cr_text;                                                                              

insert into cr_text (text_data) values ('');                                             

alter table cr_text enable trigger cr_text_tr; 


CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE

	v_object_id	integer;
	v_employees	integer;
	v_poadmins	integer;

BEGIN
	SELECT group_id INTO v_employees FROM groups where group_name = ''P/O Admins'';

	SELECT group_id INTO v_poadmins FROM groups where group_name = ''Employees'';


	-- Xowiki View Component
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Xowiki View Component'' AND page_url = ''/intranet/projects/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');

	-- Xowiki Weblog Component
	SELECT plugin_id INTO v_object_id FROM im_component_plugins WHERE plugin_name = ''Project Weblog Component'' AND page_url = ''/intranet/projects/view'';

	PERFORM im_grant_permission(v_object_id,v_employees,''read'');
	PERFORM im_grant_permission(v_object_id,v_poadmins,''read'');


	
	RETURN 0;

END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

