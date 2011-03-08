-- upgrade-3.4.0.6.2-3.4.0.6.3.sql

SELECT acs_log__debug('/packages/intranet-confdb/sql/postgresql/upgrade/upgrade-3.4.0.6.2-3.4.0.6.3.sql','');

-- Fix issue with not setting up the type_category_type

update acs_object_types set
        status_type_table = 'im_conf_items',
        status_column = 'conf_item_status_id',
        type_column = 'conf_item_type_id',
        type_category_type = 'Intranet Conf Item Type'
where object_type = 'im_conf_item';




-----------------------------------------------------------
-- OCS Inventory DynFields

SELECT im_dynfield_attribute_new ('im_conf_item', 'ip_address', 'IP Address', 'textbox_medium', 'string', 'f');


SELECT im_dynfield_attribute_new ('im_conf_item', 'os_name', 'OS Name', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'os_version', 'OS Version', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'os_comments', 'OS Comments', 'textarea_small_nospell', 'string', 'f');

SELECT im_dynfield_attribute_new ('im_conf_item', 'win_workgroup', 'Win Workgroup', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'win_userdomain', 'Win Userdomain', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'win_company', 'Win Company', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'win_owner', 'Win Owner', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'win_product_id', 'Win Product ID', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'win_product_key', 'Win Product Key', 'textbox_medium', 'string', 'f');

SELECT im_dynfield_attribute_new ('im_conf_item', 'processor_text', 'Proc Text', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'processor_speed', 'Proc Speed', 'textbox_medium', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'processor_num', 'Proc Num', 'textbox_medium', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'sys_memory', 'Sys Memory', 'textbox_medium', 'integer', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'sys_swap', 'Sys Swap', 'textbox_medium', 'integer', 'f');

SELECT im_dynfield_attribute_new ('im_conf_item', 'ocs_id', 'OCS ID', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'ocs_deviceid', 'OCS Device ID', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'ocs_username', 'OCS Username', 'textbox_medium', 'string', 'f');
SELECT im_dynfield_attribute_new ('im_conf_item', 'ocs_last_update', 'OCS Last Update', 'textbox_medium', 'string', 'f');



