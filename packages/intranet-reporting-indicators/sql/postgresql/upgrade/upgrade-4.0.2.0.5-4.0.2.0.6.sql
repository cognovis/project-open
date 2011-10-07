-- upgrade-4.0.2.0.5-4.0.2.0.6.sql

SELECT acs_log__debug('/packages/intranet-reporting-indicators/sql/postgresql/upgrade/upgrade-4.0.2.0.5-4.0.2.0.6.sql','');


select im_category_new (15255, 'Helpdesk', 'Intranet Indicator Section');


