-- upgrade-3.2.3.0.0-3.2.4.0.0.sql



create or replace function im_component_plugin__del_module (varchar) returns integer as '
DECLARE
        p_module_name   alias for $1;
        row             RECORD;
BEGIN
        for row in
            select plugin_id
            from im_component_plugins
            where package_name = p_module_name
        loop
            delete from im_component_plugin_user_map
            where plugin_id = row.plugin_id;

            PERFORM im_component_plugin__delete(row.plugin_id);
        end loop;

        return 0;
end;' language 'plpgsql';

