-- upgrade-3.4.0.5.0-3.4.0.5.1.sql

SELECT acs_log__debug('/packages/intranet-cost/sql/postgresql/upgrade/upgrade-3.4.0.5.0-3.4.0.5.1.sql','');


update im_view_columns set
	column_name = 'Effective Date',
	column_render_tcl = '$effective_date_formatted'
where
	column_id = 22013;




SELECT im_menu__delete((select menu_id from im_menus where label = 'costs'));
SELECT im_menu__delete((select menu_id from im_menus where label = 'finance_exchange_rates'));
SELECT im_menu__delete((select menu_id from im_menus where label = 'finance_expenses'));

