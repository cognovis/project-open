-- upgrade-3.4.0.6.0-3.4.0.6.1.sql

SELECT acs_log__debug('/packages/intranet-expenses/sql/postgresql/upgrade/upgrade-upgrade-3.4.0.6.0-3.4.0.6.1.sql','');

delete from acs_object_type_tables where object_type = 'im_expense';

-- im_expense is a sub-type of im_costs, so it needs to define both
-- tables as "extension tables".
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_expense', 'im_expenses', 'expense_id');
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_expense', 'im_costs', 'cost_id');




delete from acs_object_type_tables where object_type = 'im_expense_bundle';

-- im_expense_bundle is a sub-type of im_costs, so it needs to define
-- both tables as "extension tables".
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_expense_bundle', 'im_expense_bundles', 'bundle_id');
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_expense_bundle', 'im_costs', 'cost_id');

