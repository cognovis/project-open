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

create or replace function inline_0 ()
returns integer as '
declare
  v_user_id             users.user_id%TYPE;
  v_supertype           acs_object_types.supertype%TYPE;
  v_id                  cm_modules.module_id%TYPE;
  attr_id               acs_attributes.attribute_id%TYPE;
  v_module_id           cm_modules.module_id%TYPE;
  v_module_val          record;
  v_sitemap_perms       record;
begin

  select
    supertype into v_supertype
  from
    acs_object_types
  where
    object_type = ''content_module'';

  if v_supertype != ''content_item'' then

    -- delete all existing modules (they will be recreated)
    delete from acs_permissions 
      where object_id in (select module_id from cm_modules);

    for v_module_val in select
                          module_id
                        from
                          cm_modules
    LOOP
      PERFORM acs_object__delete ( v_module_val.module_id );
    end LOOP;

    attr_id := acs_attribute__create_attribute (
	''content_module'',
	''key'',
	''string'',
	''Key'',
	''Keys'',
	null,
	null,
	null,
	1,
	1,
	null,
	''type_specific'',
	''f''
	);

    attr_id := acs_attribute__create_attribute (
	''content_module'',
	''name'',
	''string'',
	''Name'',
	''Names'',
	null,
	null,
	null,
	1,
	1,
	null,
	''type_specific'',
	''f''
	);

    attr_id := acs_attribute__create_attribute (
       ''content_module'',
       ''sort_key'',
       ''number'',
       ''Sort Key'',
       ''Sort Keys'',
       null,
       null,
       null,
       1,
       1,
       null,
       ''type_specific'',
       ''f''
       );

    v_id := content_module__new(''My Tasks'', ''workspace'', NULL, 1,0);
    v_id := content_module__new(''Site Map'', ''sitemap'', 
                                 content_item__get_root_folder(), 2,0);
    v_id := content_module__new(''Templates'', ''templates'', 
                                 content_template__get_root_folder(), 3,0);
    v_id := content_module__new(''Content Types'', ''types'', 
                                 ''content_revision'', 4,0);
    v_module_id := v_id;

    v_id := content_module__new(''Search'', ''search'', null, 5,0);
    v_id := content_module__new(''Subject Keywords'', ''categories'', 0, 6,0);
    v_id := content_module__new(''Users'', ''users'', null, 7,0);
    v_id := content_module__new(''Workflows'', ''workflow'', null, 8,0);

    -- upgrade hack, grant users with sitemap privs permission on types module
    for v_sitemap_perms in 
    select
      grantee_id, privilege
    from
      acs_permissions
    where
      object_id = content_item__get_root_folder()
    LOOP
      PERFORM acs_permission__grant_permission( v_module_id, 
          v_sitemap_perms.grantee_id, v_sitemap_perms.privilege );
    end loop;

  end if;

  return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

