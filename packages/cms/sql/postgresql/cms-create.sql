-- Data model to support content repository of the ArsDigita
-- Publishing System; define a "module" object type

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- Ensure that content repository data model is up-to-date

\i cms-update.sql

create or replace function inline_0 ()
returns integer as '
declare
 attr_id	acs_attributes.attribute_id%TYPE;
begin

 PERFORM acs_object_type__create_type (
   ''content_module'',
   ''Content Module'',
   ''Content Modules'',
   ''content_item'',
   ''cm_modules'',
   ''module_id'',
   null,
   ''f'',
   null,
   ''content_module__get_label''
   );

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


  return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


-- show errors


create table cm_modules (
  module_id                  integer
                             constraint cm_modules_id_fk references
                             acs_objects on delete cascade
		             constraint cm_modules_pk 
                             primary key,
  key	     		     varchar(20)
			     constraint cm_modules_unq
			     unique,
  name			     varchar(100)
			     constraint cm_modules_name_nil
			     not null,
  root_key                   varchar(100),
  sort_key		     integer
);

comment on column cm_modules.root_key is '
  The value of the ID or key at the root of the module hierarchy.
';

-- create or replace package content_module
-- as
-- 
-- function new (
--   name          in cm_modules.name%TYPE,
--   key           in cm_modules.key%TYPE,
--   root_key      in cm_modules.root_key%TYPE,
--   sort_key      in cm_modules.sort_key%TYPE,
--   parent_id     in acs_objects.context_id%TYPE default null,
--   object_id	in acs_objects.object_id%TYPE default null,
--   creation_date	in acs_objects.creation_date%TYPE
-- 			   default sysdate,
--   creation_user	in acs_objects.creation_user%TYPE
-- 			   default null,
--   creation_ip	in acs_objects.creation_ip%TYPE default null,
--   object_type   in acs_objects.object_type%TYPE default 'content_module'
-- ) return acs_objects.object_id%TYPE;
-- 
-- 
-- function get_label (
--   --/** Returns the label for the module. 
--   --    This function is the default name method for the module object
--   --    @author Michael Pih
--   --    @param module_id        The module id
--   --    @return The module's label
--   --*/
--   module_id in cm_modules.module_id%TYPE
-- ) return cm_modules.name%TYPE;
-- 
-- 
-- end content_module;

-- show errors

-- create or replace package body content_module

create or replace function content_module__new (varchar,varchar,varchar,integer,integer)
returns integer as '
declare
  p_name                        alias for $1;  
  p_key                         alias for $2;  
  p_root_key                    alias for $3;  
  p_sort_key                    alias for $4;  
  p_parent_id                   alias for $5;  -- default null
begin

        return content_module__new(p_name,
                                   p_key,
                                   p_root_key,
                                   p_sort_key,
                                   p_parent_id,
                                   null,
                                   now(),
                                   null,
                                   null,
                                   ''content_module''
                                   );
end;' language 'plpgsql';

create or replace function content_module__new (varchar,varchar,integer,integer,integer)
returns integer as '
begin
    return content_module__new ($1, $2, cast ($3 as varchar), $4, $5);
end;' language 'plpgsql';

-- function new
create or replace function content_module__new (varchar,varchar,varchar,integer,integer,integer,timestamptz,integer,varchar,varchar)
returns integer as '
declare
  p_name                        alias for $1;  
  p_key                         alias for $2;  
  p_root_key                    alias for $3;  
  p_sort_key                    alias for $4;  
  p_parent_id                   alias for $5;  -- null  
  p_object_id                   alias for $6;  -- null
  p_creation_date               alias for $7;  -- now()
  p_creation_user               alias for $8;  -- null
  p_creation_ip                 alias for $9;  -- null
  p_object_type                 alias for $10; -- ''content_module''
  v_module_id                   integer;       
begin
  v_module_id := content_item__new(
      p_name,
      p_parent_id,
      p_object_id,
      null,
      p_creation_date,
      p_creation_user,
      null,
      p_creation_ip,
      ''content_module'',
      p_object_type,
      null,
      null,
      ''text/plain'',
      null,
      null,
      ''file''
  );

  insert into cm_modules
    (module_id, key, name, root_key, sort_key)
  values
    (v_module_id, p_key, p_name, p_root_key, p_sort_key);

  return v_module_id;

end;' language 'plpgsql';


create or replace function content_module__get_label (integer) returns varchar as '
declare
        p_module_id     alias for $1;
        v_name          cm_modules.name%TYPE;
begin

  select
    coalesce(name,key) into v_name
  from
    cm_modules
  where
    module_id = p_module_id;

  return v_name;

end;' language 'plpgsql';

-- Insert the default modules
create or replace function inline_1 () returns integer as '
declare 
  v_id		integer;
  v_module_id	integer;
begin

  v_id := content_module__new(''My Tasks'', ''workspace'', NULL, 1,0);
  v_id := content_module__new(''Site Map'', ''sitemap'', 
    content_item__get_root_folder(null), 2,0);
  v_id := content_module__new(''Templates'', ''templates'', 
    content_template__get_root_folder(), 3,0);
  v_id := content_module__new(''Content Types'', ''types'', 
    ''content_revision'', 4,0);
  v_id := content_module__new(''Search'', ''search'', null, 5,0);
  v_id := content_module__new(''Subject Keywords'', ''categories'', 0, 6,0);
  v_id := content_module__new(''Users'', ''users'', null, 7,0);
  v_id := content_module__new(''Workflows'', ''workflow'', null, 8,0);

  return null;

end;' language 'plpgsql';

select inline_1 ();

drop function inline_1 ();

-- prompt *** Defining utility functions 

-- Get the alphabetical ordering of a string, based on the first
-- character. Treat all non-alphabetical characters as before ''a''
create or replace function letter_placement (varchar) returns integer as '
declare
  p_word          alias for $1;
  v_letter        varchar(1);
begin

  v_letter := substr(lower(p_word), 1, 1);
   
  if v_letter < ''a'' or v_letter > ''z'' then
    return ascii(''a'') - 1;
  else
    return ascii(v_letter);
  end if;

end;' language 'plpgsql';

-- prompt *** Compiling metadata forms package...
\i cms-forms.sql

-- prompt *** Compiling content methods model...
\i cms-content-methods.sql

-- prompt *** Compiling workflow model...
\i cms-publishing-wf.sql

-- prompt *** Compiling workflow helper package...
\i cms-workflow.sql

-- prompt *** Compiling permissions model...
\i cms-permissions.sql

-- prompt *** Compiling fixes that need to be done...
\i cms-fix.sql
 

