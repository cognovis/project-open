-- upgrade-3.4.0.7.5-3.4.0.7.6.sql

SELECT acs_log__debug('/packages/intranet-contacts/sql/postgresql/upgrade/upgrade-3.4.0.7.5-3.4.0.7.6.sql','');




-------------------------------------------------------------------
-- Create DynFields
-------------------------------------------------------------------



-- im_dynfield_attribute_new (o_type, column, pretty_name, widget_name, data_type, required_p, pos, also_hard_coded_p)

SELECT im_dynfield_attribute_new ('person', 'first_names', '#acs-subsite.first_names#', 'textbox_medium', 'string', 't', 0, 't');
SELECT im_dynfield_attribute_new ('person', 'last_name', '#acs-subsite.last_name#', 'textbox_medium', 'string', 't', 1, 't');
SELECT im_dynfield_attribute_new ('party', 'email', '#acs-subsite.Email#', 'textbox_medium', 'string', 't', 2, 't');
SELECT im_dynfield_attribute_new ('party', 'url', '#acs-subsite.URL#', 'textbox_medium', 'string', 't', 3, 't');



-- Salutation
SELECT im_dynfield_attribute_new ('person', 'salutation_id', '#intranet-contacts.Salutation#', 'salutation', 'integer', 'f', 4, 'f');

-- Companies
SELECT im_dynfield_attribute_new ('im_company', 'company_name', '#intranet-core.Company_Name#', 
	'textbox_medium', 'string', 't', 1, 't');

SELECT im_dynfield_attribute_new ('im_company', 'company_path', '#intranet-core.Company_Path#', 
	'textbox_medium', 'string', 't', 1, 't');

SELECT im_dynfield_attribute_new ('im_company', 'company_status_id', '#intranet-core.Company_Status#', 
	'category_company_status', 'integer', 't', 1, 't');

SELECT im_dynfield_attribute_new ('im_company', 'company_type_id', '#intranet-core.Company_Types#', 
	'category_company_type', 'integer', 't', 1, 't');


