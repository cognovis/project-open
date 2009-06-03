-- upgrade-3.4.0.6.0-3.4.0.6.1.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.6.0-3.4.0.6.1.sql','');


update im_menus set
	menu_gif_small = 'arrow_right'
where
	parent_menu_id in (
		select	menu_id
		from	im_menus
		where	label = 'admin'
	)
;

