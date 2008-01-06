-- upgrade-3.3.1.1.0-3.3.1.2.0.sql

update im_categories 
set category = 'Expense Bundle'
where category_id = 3722;

