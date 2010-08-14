-- upgrade-3.4.1.0.4-3.4.1.0.5.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.1.0.4-3.4.1.0.5.sql','');

SELECT im_lang_add_message('en_US','intranet-expenses','Expense_Report','Expense Report');
SELECT im_lang_add_message('en_US','intranet-core','Date_submitted','Date submitted');
SELECT im_lang_add_message('en_US','intranet-core','Amount_due','Amount due');
SELECT im_lang_add_message('en_US','intranet-core','Print_date','Print date');
SELECT im_lang_add_message('en_US','intranet-cost','Number_billable_expenses','Number billable expenses');


update currency_codes set
	currency_name = 'Argentinian Peso (obsolete)'
where
	iso = 'ARP';

insert into currency_codes values ('ARS','Argentinian Peso','f','');

