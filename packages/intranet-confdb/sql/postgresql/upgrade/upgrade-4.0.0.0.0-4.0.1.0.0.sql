-- upgrade-4.0.0.0.0-4.0.1.0.0.sql

SELECT acs_log__debug('/packages/intranet-confdb/sql/postgresql/upgrade/upgrade-4.0.0.0.0-4.0.1.0.0.sql','');


SELECT im_category_new(11810, 'Service', 'Intranet Conf Item Type');



-- Types of Services
SELECT im_category_new(12400, 'CVS Repository', 'Intranet Conf Item Type');
SELECT im_category_hierarchy_new('CVS Repository','Service','Intranet Conf Item Type');
-- reserved to 12499

