-- upgrade-4.0.3.0.3-4.0.3.0.4.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-tasks/sql/postgresql/upgrade/upgrade-4.0.3.0.3-4.0.3.0.4.sql','');




-------------------------------
-- Timesheet Task Scheduling Type
SELECT im_category_new(9700,'As soon as possible', 'Intranet Timesheet Task Scheduling Type');
SELECT im_category_new(9701,'As late as possible', 'Intranet Timesheet Task Scheduling Type');
SELECT im_category_new(9702,'Must start on', 'Intranet Timesheet Task Scheduling Type');
SELECT im_category_new(9703,'Must finish on', 'Intranet Timesheet Task Scheduling Type');
SELECT im_category_new(9704,'Start no earlier than', 'Intranet Timesheet Task Scheduling Type');
SELECT im_category_new(9705,'Start no later than', 'Intranet Timesheet Task Scheduling Type');
SELECT im_category_new(9706,'Finish no earlier than', 'Intranet Timesheet Task Scheduling Type');
SELECT im_category_new(9707,'Finish no later than', 'Intranet Timesheet Task Scheduling Type');

update im_categories set aux_int1 = 0 where category_id = 9700;
update im_categories set aux_int1 = 1 where category_id = 9701;
update im_categories set aux_int1 = 2 where category_id = 9702;
update im_categories set aux_int1 = 3 where category_id = 9703;
update im_categories set aux_int1 = 4 where category_id = 9704;
update im_categories set aux_int1 = 5 where category_id = 9705;
update im_categories set aux_int1 = 6 where category_id = 9706;
update im_categories set aux_int1 = 7 where category_id = 9707;

