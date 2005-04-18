-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Thomas Kuczek (thomas@arsdigita.com)
-- $Id$

-- In order for Form Widget Wizard to work, the default value
-- for the select form widget options param needs to be fixed

update cm_form_widget_params 
  set default_value = '{ -- {} }' 
  where param_id = 60;


-- content_module inherit from content_item
-- this way it is possible to grant permissions on content modules

declare
  cursor c_module_cur is
    select
      module_id
    from
      cm_modules;

  v_user_id   users.user_id%TYPE;
  v_supertype acs_object_types.supertype%TYPE;
  v_id	      cm_modules.module_id%TYPE;
  attr_id     acs_attributes.attribute_id%TYPE;
  v_module_id cm_modules.module_id%TYPE;

  -- this is an upgrade hack
  cursor c_sitemap_perms_cur is
    select
      grantee_id, privilege
    from
      acs_permissions
    where
      object_id = content_item.get_root_folder;
begin

  select
    supertype into v_supertype
  from
    acs_object_types
  where
    object_type = 'content_module';

  if v_supertype ^= 'content_item' then

    -- delete all existing modules (they will be recreated)
    delete from acs_permissions 
      where object_id in (select module_id from cm_modules);
    for v_module_val in c_module_cur loop
      acs_object.del( v_module_val.module_id );
    end loop;

    acs_object_type.drop_type ( 'content_module' );

    acs_object_type.create_type (
        supertype     => 'content_item',
        object_type   => 'content_module',
        pretty_name   => 'Content Module',
        pretty_plural => 'Content Modules',
        table_name    => 'cm_modules',
        id_column     => 'module_id',
        name_method   => 'content_module.get_label'
    );

    attr_id := acs_attribute.create_attribute (
        object_type    => 'content_module',
	attribute_name => 'key',
	datatype       => 'string',
	pretty_name    => 'Key',
	pretty_plural  => 'Keys'
    ); 

    attr_id := acs_attribute.create_attribute (
        object_type    => 'content_module',
	attribute_name => 'name',
	datatype       => 'string',
	pretty_name    => 'Name',
	pretty_plural  => 'Names'
    ); 

    attr_id := acs_attribute.create_attribute (
       object_type    => 'content_module',
       attribute_name => 'sort_key',
       datatype       => 'number',
       pretty_name    => 'Sort Key',
       pretty_plural  => 'Sort Keys'
    );

    v_id := content_module.new('My Tasks', 'workspace', NULL, 1,0);
    v_id := content_module.new('Site Map', 'sitemap', 
                                 content_item.get_root_folder, 2,0);
    v_id := content_module.new('Templates', 'templates', 
                                 content_template.get_root_folder, 3,0);
    v_id := content_module.new('Content Types', 'types', 
                                 'content_revision', 4,0);
    v_module_id := v_id;

    v_id := content_module.new('Search', 'search', null, 5,0);
    v_id := content_module.new('Subject Keywords', 'categories', 0, 6,0);
    v_id := content_module.new('Users', 'users', null, 7,0);
    v_id := content_module.new('Workflows', 'workflow', null, 8,0);

    -- upgrade hack, grant users with sitemap privs permission on types module
    for v_sitemap_perms in c_sitemap_perms_cur loop
      acs_permission.grant_permission( v_module_id, 
          v_sitemap_perms.grantee_id, v_sitemap_perms.privilege );
    end loop;

  end if;

end;
/
show errors
