-- upgrade-3.4.0.8.0-3.4.0.8.1.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.8.0-3.4.0.8.1.sql','');

-- Disable "Active or Potential" company status
update im_categories set enabled_p = 'f' where category_id = 40;

