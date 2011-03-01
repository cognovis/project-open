--  upgrade-3.4.0.8.5-3.4.0.8.6.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.4.0.8.5-3.4.0.8.6.sql','');


-- Move the checkbox to the first column of the table TransTaskList.
update im_view_columns set sort_order = 0
where column_id = 9021;
