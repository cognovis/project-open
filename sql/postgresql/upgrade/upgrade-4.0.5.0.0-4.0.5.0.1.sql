-- upgrade4.0.5.0.0-4.0.5.0.1.sql
SELECT acs_log__debug('/packages/intranet-invoices/sql/postgresql/upgrade/upgrade-4.0.5.0.0-4.0.5.0.1.sql','');

-- Defined InterCo Quote and Invoices as provider document
-- 
SELECT im_category_hierarchy_new(3730,3708);
SELECT im_category_hierarchy_new(3732,3708);

-- Provider Receipt is a Provider Document
SELECT im_category_hierarchy_new(3734,3710);


