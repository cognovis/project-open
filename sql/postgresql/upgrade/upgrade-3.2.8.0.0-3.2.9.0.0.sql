-- upgrade-3.2.8.0.0-3.2.9.0.0.sql


alter table persons add demo_group varchar(50);
alter table persons add demo_password varchar(50);





-------------------------------------------------------------
-- Slow query for Employees (the most frequent one...)
-- because of missing outer-join reordering in PG 7.4...
-- Now adding the "im_employees" (in extra-from/extra-where)
-- INSIDE the basic query.

update im_view_columns set extra_from = null, extra_where = null where column_id = 5500;



