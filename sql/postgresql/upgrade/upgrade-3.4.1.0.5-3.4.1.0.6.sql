-- upgrade-3.4.1.0.5-3.4.1.0.6.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.1.0.5-3.4.1.0.6.sql','');

-- configure ajax columns
alter table im_view_columns add ajax_configuration varchar(1000);
SELECT im_category_new (1415, 'Ajax', 'Intranet DynView Type');

