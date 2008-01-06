-- upgrade-3.3.1.1.0-3.3.1.2.0.sql

update im_categories 
set category = 'Expense Bundle'
where category_id = 3722;


select acs_privilege__create_privilege('fi_read_expense_bundles','Read Expense Bundles','Read Expense Bundles');
select acs_privilege__create_privilege('fi_write_expense_bundles','Write Expense Bundles','Write Expense Bundles');
select acs_privilege__add_child('fi_read_all', 'fi_read_expense_bundles');
select acs_privilege__add_child('fi_write_all', 'fi_write_expense_bundles');

