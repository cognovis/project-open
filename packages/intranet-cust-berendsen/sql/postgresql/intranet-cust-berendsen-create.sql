insert into ad_locales values ('de_DE_BER', 'de', 'DE', 'BER', 'German (Berendsen)', 'GERMAN', 'GERMANY', 'WE8ISO8859P1', 'ISO-8859-1', 'f', 't');

select im_component_plugin__new (
        null,                                   -- plugin_id                                                      
       'acs_object',                           -- object_type                                                                 
        now(),                                  -- creation_date                                   
        null,                                   -- creation_user                             
        null,                                   -- creattion_ip 
        null,                                   -- context_id 
        'Priorisierte Projekte',              -- plugin_name
        'intranet-cust-berendsen',            -- package_name
        'left',                                 -- location 
        '/intranet/index',              -- page_url 
        null,                                   -- view_name
        50,                                     -- sort_order 
        'im_project_personal_active_projects_component -project_status_id 10000022'
);

SELECT im_category_new (1307,'Lenkungsausschuss','Intranet Biz Object Role');
insert into im_biz_object_role_map values ('im_project',86,1307);
insert into im_biz_object_role_map values ('im_project',85,1307);

SELECT im_category_new (10000011,'Organisationsoptimierung','Intranet Projekt Type');
SELECT im_category_new (10000012,'Strategieprojekte','Intranet Projekt Type');
SELECT im_category_new (10000031,'Neue Dienstleistungen','Intranet Projekt Type');
SELECT im_category_new (10000032,'Prozessoptimierung','Intranet Projekt Type');
SELECT im_category_new (10000033,'Infrastruktur','Intranet Projekt Type');
SELECT im_category_new (10000034,'Neue Produkte','Intranet Projekt Type');
SELECT im_category_new (10000035,'Kundenprojekte','Intranet Projekt Type');

SELECT im_category_hierarchy_new(10000011,2501);
SELECT im_category_hierarchy_new(10000012,2501);
SELECT im_category_hierarchy_new(10000031,2501);
SELECT im_category_hierarchy_new(10000032,2501);
SELECT im_category_hierarchy_new(10000033,2501);
SELECT im_category_hierarchy_new(10000034,2501);
SELECT im_category_hierarchy_new(10000035,2501);

SELECT im_category_new (10000013,'beantragt','Intranet Projekt Status');
SELECT im_category_new (10000014,'Antrag unvollständig','Intranet Projekt Status');
SELECT im_category_new (10000015,'Prüfung MPK','Intranet Projekt Status');
SELECT im_category_new (10000016,'Detailplanung','Intranet Projekt Status');
SELECT im_category_new (10000017,'abgelehnt','Intranet Projekt Status');
SELECT im_category_new (10000018,'zurückgestellt','Intranet Projekt Status');
SELECT im_category_new (10000020,'erledigt','Intranet Projekt Status');
SELECT im_category_new (10000021,'gestoppt','Intranet Projekt Status');
SELECT im_category_new (10000022,'priorisiert','Intranet Projekt Status');
SELECT im_category_new (10000023,'Überprüfung Detailplanung','Intranet Projekt Status');
SELECT im_category_new (10000024,'in Bearbeitung','Intranet Projekt Status');


-- -------------------------------
-- Create the menu item
-- -------------------------------

SELECT im_menu__new (
	null,					-- p_menu_id
	'acs_object',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'intranet-berendsen',		-- package_name
	'berendsen_beantragt',			-- label
	'beantragt',			-- name
	'/intranet/projects/index?project_status_id=10000013&view_name=project_list',	-- url
	30,					-- sort_order
	(select menu_id from im_menus where label = 'projects'),
	null					-- p_visible_tcl
);



SELECT acs_permission__grant_permission(
	(select menu_id from im_menus where label = 'berendsen_beantragt'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

-------------- 
-- Detailplanung
--------------

SELECT im_menu__new (
        null,                                   -- p_menu_id                                                                           
        'acs_object',                           -- object_type                                                                         
        now(),                                  -- creation_date                                                                       
        null,                                   -- creation_user                                                                       
        null,                                   -- creation_ip                                                                         
        null,                                   -- context_id                                                                          
        'intranet-berendsen',           -- package_name                                                                                
        'berendsen_detailplanung',                  -- label                                                                               
        'Detailplanung',                    -- name                                                                                        
        '/intranet/projects/index?project_status_id=10000016&view_name=project_list',   -- url                                         
        31,                                     -- sort_order                                                                          
        (select menu_id from im_menus where label = 'projects'),
        null                                    -- p_visible_tcl                                                                       
);



SELECT acs_permission__grant_permission(
        (select menu_id from im_menus where label = 'berendsen_detailplanung'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);

-------------- 
-- Priorisiert
--------------

SELECT im_menu__new (
        null,                                   -- p_menu_id                                                                           
        'acs_object',                           -- object_type                                                                         
        now(),                                  -- creation_date                                                                       
        null,                                   -- creation_user                                                                       
        null,                                   -- creation_ip                                                                         
        null,                                   -- context_id                                                                          
        'intranet-berendsen',           -- package_name                                                                                
        'berendsen_priorisiert',                  -- label                                                                               
        'Priorisiert',                    -- name                                                                                        
        '/intranet/projects/index?project_status_id=10000022&view_name=project_list',   -- url                                         
        32,                                     -- sort_order                                                                          
        (select menu_id from im_menus where label = 'projects'),
        null                                    -- p_visible_tcl                                                                       
);



SELECT acs_permission__grant_permission(
        (select menu_id from im_menus where label = 'berendsen_priorisiert'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);


----------------
- Berendsen Department Planner
----------------

insert into im_views (view_id, view_name, visible_for, view_type_id)
values (921, 'portfolio_department_planner_list_ajax', 'view_users', 1415);

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (141501,921,NULL,'',
'Priority','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (141502,921,NULL,'',
'Priority (op)','','',10,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (141503,921,NULL,'',
'Project','','',15,'');