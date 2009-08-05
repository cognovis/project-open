-- upgrade-3.4.0.7.2-3.4.0.7.3.sql

SELECT acs_log__debug('/packages/intranet-confdb/sql/postgresql/upgrade/upgrade-3.4.0.7.2-3.4.0.7.3.sql','');


-- Types of Processes
SELECT im_category_new(12300, 'Project Open Process', 'Intranet Conf Item Type'); 
SELECT im_category_new(12302, 'PostgreSQL Process', 'Intranet Conf Item Type'); 
SELECT im_category_new(12304, 'Postfix Process', 'Intranet Conf Item Type'); 
SELECT im_category_new(12306, 'Pound Process', 'Intranet Conf Item Type'); 
SELECT im_category_hierarchy_new('Project Open Server','Process','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('PostgreSQL Process','Process','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Postfix Process','Process','Intranet Conf Item Type');
SELECT im_category_hierarchy_new('Pound Process','Process','Intranet Conf Item Type');

-- reserved to 12399
