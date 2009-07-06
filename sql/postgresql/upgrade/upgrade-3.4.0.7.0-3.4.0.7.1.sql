-- upgrade-3.4.0.7.0-3.4.0.7.1.sql

SELECT acs_log__debug('/packages/intranet-dynfield/sql/postgresql/upgrade/upgrade-3.4.0.7.0-3.4.0.7.1.sql','');



SELECT im_menu__new (
        null,                                                   -- p_menu_id
        'im_menu',                                              -- object_type
        now(),                                                  -- creation_date
        null,                                                   -- creation_user
        null,                                                   -- creation_ip
        null,                                                   -- context_id
        'intranet-dynfield',                                    -- package_name
        'dynfield_otype_conf_item',                             -- label
        'Conf Item',                                            -- name
        '/intranet-dynfield/object-type?object_type=im_conf_item', -- url
        112,                                                    -- sort_order
        (select menu_id from im_menus where label = 'dynfield_otype'),  -- parent_menu_id
        null                                                    -- p_visible_tcl
);



SELECT im_menu__new (
        null,                                                   -- p_menu_id
        'im_menu',                                              -- object_type
        now(),                                                  -- creation_date
        null,                                                   -- creation_user
        null,                                                   -- creation_ip
        null,                                                   -- context_id
        'intranet-dynfield',                                    -- package_name
        'dynfield_otype_expense_bundles',                       -- label
        'Expense Bundle',                                       -- name
        '/intranet-dynfield/object-type?object_type=im_expense_bundle', -- url
        122,                                                    -- sort_order
        (select menu_id from im_menus where label = 'dynfield_otype'),  -- parent_menu_id
        null                                                    -- p_visible_tcl
);


SELECT im_menu__new (
	null,							-- p_menu_id
	'im_menu',						-- object_type
	now(),							-- creation_date
	null,							-- creation_user
	null,							-- creation_ip
	null,							-- context_id
	'intranet-dynfield',					-- package_name
	'dynfield_otype_invoice',				-- label
	'Invoice',						-- name
	'/intranet-dynfield/object-type?object_type=im_invoice', -- url
	142,							-- sort_order
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
	'dynfield_otype_note',					-- label
	'Note',							-- name
	'/intranet-dynfield/object-type?object_type=im_note',	-- url
	144,							-- sort_order
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
	'dynfield_otype_ticket',				-- label
	'Ticket',						-- name
	'/intranet-dynfield/object-type?object_type=im_ticket',	-- url
	180,							-- sort_order
	(select menu_id from im_menus where label = 'dynfield_otype'),	-- parent_menu_id
	null							-- p_visible_tcl
);



update im_menus set name = 'Absence' where name = 'Absences' and package_name = 'intranet-dynfield';
update im_menus set name = 'Company' where name = 'Companies' and package_name = 'intranet-dynfield';
update im_menus set name = 'Conf Item' where name = 'Conf Items' and package_name = 'intranet-dynfield';
update im_menus set name = 'Expense' where name = 'Expenses' and package_name = 'intranet-dynfield';
update im_menus set name = 'Expense Bundle' where name = 'Expense Bundles' and package_name = 'intranet-dynfield';
update im_menus set name = 'RFQ' where name = 'Freelance RFQ' and package_name = 'intranet-dynfield';
update im_menus set name = 'RFQ Answer' where name = 'Freelance RFQ Answer' and package_name = 'intranet-dynfield';
update im_menus set name = 'Invoice' where name = 'Invoices' and package_name = 'intranet-dynfield';
update im_menus set name = 'Note' where name = 'Notes' and package_name = 'intranet-dynfield';
update im_menus set name = 'Office' where name = 'Offices' and package_name = 'intranet-dynfield';
update im_menus set name = 'Person' where name = 'Persons' and package_name = 'intranet-dynfield';
update im_menus set name = 'Project' where name = 'Projects' and package_name = 'intranet-dynfield';
update im_menus set name = 'Ticket' where name = 'Tickets' and package_name = 'intranet-dynfield';




