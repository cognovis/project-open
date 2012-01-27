-- upgrade-4.0.2.0.0-4.0.2.0.1.sql

SELECT acs_log__debug('/packages/intranet-sencha-ticket-tracker/sql/postgresql/upgrade/upgrade-4.0.2.0.0-4.0.2.0.1.sql','');

update persons
set language = 'es_ES'
where language = 'en_ES';

