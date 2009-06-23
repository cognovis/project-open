-- upgrade-3.4.0.6.2-3.4.0.6.3.sql

SELECT acs_log__debug('/packages/intranet-confdb/sql/postgresql/upgrade/upgrade-3.4.0.6.2-3.4.0.6.3.sql','');

-- Fix issue with not setting up the type_category_type

update acs_object_types set
        status_type_table = 'im_conf_items',
        status_column = 'conf_item_status_id',
        type_column = 'conf_item_type_id',
        type_category_type = 'Intranet Conf Item Type'
where object_type = 'im_conf_item';


