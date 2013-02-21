-- upgrade-4.0.3.5.0-4.0.3.5.1.sql

SELECT acs_log__debug('/packages/intranet-riskmanagement/sql/postgresql/upgrade/upgrade-4.0.3.5.0-4.0.3.5.1.sql','');


update im_categories
set category = 'Open'
where category_id = 75000;


update im_categories
set category = 'Closed'
where category_id = 75002;

SELECT im_category_new (75098, 'Deleted', 'Intranet Risk Status');

update im_categories
set category = 'Risk'
where category_id = 75100;

update im_categories
set category = 'Issue'
where category_id = 75002;

SELECT im_category_new (75102, 'Issue', 'Intranet Risk Type');
