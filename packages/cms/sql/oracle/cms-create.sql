-- Data model to support content repository of the ArsDigita
-- Publishing System; define a "module" object type

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- Ensure that content repository data model is up-to-date

@@cms-update.sql

declare
 attr_id	acs_attributes.attribute_id%TYPE;
begin

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


end;
/
show errors


create table cm_modules (
  module_id                  integer
                             constraint cm_modules_id_fk references
                             acs_objects on delete cascade
		             constraint cm_modules_pk 
                             primary key,
  key	     		     varchar2(20)
			     constraint cm_modules_unq
			     unique,
  name			     varchar2(100)
			     constraint cm_modules_name_nil
			     not null,
  root_key                   varchar2(100),
  sort_key		     integer
);

comment on column cm_modules.root_key is '
  The value of the ID or key at the root of the module hierarchy.
';

create or replace package content_module
as

function new (
  name          in cm_modules.name%TYPE,
  key           in cm_modules.key%TYPE,
  root_key      in cm_modules.root_key%TYPE,
  sort_key      in cm_modules.sort_key%TYPE,
  parent_id     in acs_objects.context_id%TYPE default null,
  object_id	in acs_objects.object_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  object_type   in acs_objects.object_type%TYPE default 'content_module'
) return acs_objects.object_id%TYPE;


function get_label (
  --/** Returns the label for the module. 
  --    This function is the default name method for the module object
  --    @author Michael Pih
  --    @param module_id        The module id
  --    @return The module's label
  --*/
  module_id in cm_modules.module_id%TYPE
) return cm_modules.name%TYPE;


end content_module;
/
show errors

create or replace package body content_module
as

function new (
  name          in cm_modules.name%TYPE,
  key           in cm_modules.key%TYPE,
  root_key      in cm_modules.root_key%TYPE,
  sort_key      in cm_modules.sort_key%TYPE,
  parent_id     in acs_objects.context_id%TYPE default null,
  object_id	in acs_objects.object_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  object_type   in acs_objects.object_type%TYPE default 'content_module'
) return acs_objects.object_id%TYPE
is
  module_id integer;
begin
  module_id := content_item.new(
      item_id       => object_id,
      parent_id     => parent_id,
      name          => name,
      content_type  => object_type,
      item_subtype  => 'content_module',
      creation_user => creation_user,
      creation_ip   => creation_ip,
      creation_date => creation_date
  );

  insert into cm_modules
    (module_id, key, name, root_key, sort_key)
  values
    (module_id, key, name, root_key, sort_key);

  return module_id;
end;


function get_label (
  module_id in cm_modules.module_id%TYPE
) return cm_modules.name%TYPE
is
  v_name cm_modules.name%TYPE;
begin

  select
    nvl(name,key) into v_name
  from
    cm_modules
  where
    module_id = get_label.module_id;

  return v_name;
  exception
    when NO_DATA_FOUND then
      return null;

end get_label;




end content_module;
/
show errors

-- Insert the default modules
declare 
  v_id		integer;
  v_module_id	integer;
begin

  v_id := content_module.new('My Tasks', 'workspace', NULL, 1,0);
  v_id := content_module.new('Site Map', 'sitemap', 
    content_item.get_root_folder, 2,0);
  v_id := content_module.new('Templates', 'templates', 
    content_template.get_root_folder, 3,0);
  v_id := content_module.new('Content Types', 'types', 
    'content_revision', 4,0);
  v_id := content_module.new('Search', 'search', null, 5,0);
  v_id := content_module.new('Subject Keywords', 'categories', 0, 6,0);
  v_id := content_module.new('Users', 'users', null, 7,0);
  v_id := content_module.new('Workflows', 'workflow', null, 8,0);

end;
/
show errors

prompt *** Defining utility functions 

-- Get the alphabetical ordering of a string, based on the first
-- character. Treat all non-alphabetical characters as before 'a'
create or replace function letter_placement (
  word in varchar2
) return integer
is
  letter varchar2(1);
begin

  letter := substr(lower(word), 1, 1);
   
  if letter < 'a' or letter > 'z' then
    return ascii('a') - 1;
  else
    return ascii(letter);
  end if;
end letter_placement;
/
show errors  

prompt *** Compiling metadata forms package...
@@ cms-forms

prompt *** Compiling content methods model...
@@ cms-content-methods

prompt *** Compiling workflow model...
@@ cms-publishing-wf

prompt *** Compiling workflow helper package...
@@ cms-workflow

prompt *** Compiling permissions model...
@@ cms-permissions

prompt *** Compiling fixes that need to be done...
@@ cms-fix
