-- upgrade-3.4.0.5.0-3.4.0.5.1.sql

SELECT acs_log__debug('/packages/intranet-reporting-finance/sql/postgresql/upgrade/upgrade-3.4.0.5.0-3.4.0.5.1.sql','');

-- Fix reinisch wrong report name
update im_menus set
	package_name = 'intranet-reporting-finance',
	url = '/intranet-reporting-finance/finance-expenses'
where
	url = '/intranet-reporting/finance-expenses'
;


