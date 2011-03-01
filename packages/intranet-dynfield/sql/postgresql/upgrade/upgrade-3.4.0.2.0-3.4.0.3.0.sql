-- upgrade-3.4.0.2.0-3.4.0.3.0.sql

SELECT acs_log__debug('/packages/intranet-dynfield/sql/postgresql/upgrade/upgrade-3.4.0.2.0-3.4.0.3.0.sql','');


---------------------------------------------------------
-- 
---------------------------------------------------------


SELECT im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-dynfield',				-- package_name
	'dynfield_otype',				-- label
	'Object Types',					-- name
	'/intranet-dynfield/object-types',		-- url
	10,						-- sort_order
	(select menu_id from im_menus where label = 'dynfield_admin'),	-- parent_menu_id
	null						-- p_visible_tcl
);

SELECT im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-dynfield',				-- package_name
	'dynfield_permission',				-- label
	'Permissions',					-- name
	'/intranet-dynfield/permissions',		-- url
	20,						-- sort_order
	(select menu_id from im_menus where label = 'dynfield_admin'),	-- parent_menu_id
	null						-- p_visible_tcl
);

SELECT im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-dynfield',				-- package_name
	'dynfield_widgets',				-- label
	'Widgets',					-- name
	'/intranet-dynfield/widgets',			-- url
	100,						-- sort_order
	(select menu_id from im_menus where label = 'dynfield_admin'),	-- parent_menu_id
	null						-- p_visible_tcl
);

SELECT im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-dynfield',				-- package_name
	'dynfield_widget_examples',			-- label
	'Widget Examples',				-- name
	'/intranet-dynfield/widget-examples',		-- url
	110,						-- sort_order
	(select menu_id from im_menus where label = 'dynfield_admin'),	-- parent_menu_id
	null						-- p_visible_tcl
);

SELECT im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-dynfield',				-- package_name
	'dynfield_doc',					-- label
	'Documentation',				-- name
	'/doc/intranet-dynfield/',			-- url
	900,						-- sort_order
	(select menu_id from im_menus where label = 'dynfield_admin'),	-- parent_menu_id
	null						-- p_visible_tcl
);



----------------------------------------------------------
-- Object Types

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_absences',				-- label
	'Absence',						-- name
	'/intranet-dynfield/object-type?object_type=im_user_absence', -- url
	100,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_companies',				-- label
	'Company',						-- name
	'/intranet-dynfield/object-type?object_type=im_company', -- url
	110,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_expenses',				-- label
	'Expense',						-- name
	'/intranet-dynfield/object-type?object_type=im_expense', -- url
	120,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_freelance_rfqs',			-- label
	'Freelance RFQ',					-- name
	'/intranet-dynfield/object-type?object_type=im_freelance_rfq', -- url
	130,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);
SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_freelance_rfq_answers',			-- label
	'Freelance RFQ Answer',					-- name
	'/intranet-dynfield/object-type?object_type=im_freelance_rfq_answer', -- url
	140,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_offices',				-- label
	'Offices',						-- name
	'/intranet-dynfield/object-type?object_type=im_office', -- url
	150,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_persons',				-- label
	'Persons',						-- name
	'/intranet-dynfield/object-type?object_type=person', -- url
	160,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_projects',				-- label
	'Projects',						-- name
	'/intranet-dynfield/object-type?object_type=im_project', -- url
	170,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);

