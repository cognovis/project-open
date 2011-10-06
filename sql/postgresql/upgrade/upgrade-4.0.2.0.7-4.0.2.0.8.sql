-- upgrade-4.0.2.0.7-4.0.2.0.8.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.2.0.7-4.0.2.0.8.sql','');


update im_menus
set enabled_p = 'f'
where label in (
	'openacs_cache',
	'admin_flush',
	'openacs_api_doc',
	'openacs_ds',
	'openacs_sitemap',
	'admin_sysconfig',
	'admin_user_exits',
	'selectors_admin',
	'admin_home',
	'openacs_developer',
	'openacs_shell',
	'openacs_auth',
	'openacs_l10n'
);
