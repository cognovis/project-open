/* 
   cms-content-method.sql

   @author Michael Pih

   Data model and package definitions for mapping content types 
   to content methods
*/



/* Data model */

/* Means of inserting content into the database. */
create table cm_content_methods (
  content_method	varchar(100)
			constraint cm_content_methods_pk
			primary key,
  label			varchar(100) not null,
  description		text
);

-- insert the standard content methods
insert into cm_content_methods (
  content_method, label, description
) values (
  'file_upload', 'File Upload', 'Upload content from a file on  your computer.'
);

insert into cm_content_methods (
  content_method, label, description
) values (
  'text_entry', 'Text Entry', 'Type content into a textbox.'
);

insert into cm_content_methods (
  content_method, label, description
) values (
  'no_content', 'No Content', 'Don''t add content.'
);

insert into cm_content_methods (
  content_method, label, description
) values (
  'xml_import', 'XML Import', 'Add content from by uploading an XML document.'
);


/* Map a content type to a content method(s) */
create table cm_content_type_method_map (
  content_type		varchar(100)
			constraint cm_type_method_map_type_fk
			references acs_object_types,
  content_method	varchar(100) default 'no_content'
			constraint cm_type_method_map_method_fk
			references cm_content_methods,
  is_default		boolean
);


/* A view of all mapped content methods */
create view cm_type_methods
as
  select
    map.content_type, t.pretty_name, 
    map.content_method, m.label, m.description, map.is_default
  from
    cm_content_methods m, cm_content_type_method_map map, 
    acs_object_types t
  where
    t.object_type = map.content_type
  and
    map.content_method = m.content_method;






/* PACKAGE DEFINITIONS */

-- create or replace package content_method as
-- 
--   function get_method (
--     content_type        in cm_content_type_method_map.content_type%TYPE
--   ) return cm_content_type_method_map.content_method%TYPE;
-- 
--   function is_mapped ( 
--     content_type        in cm_content_type_method_map.content_type%TYPE,
--     content_method	in cm_content_type_method_map.content_method%TYPE
--   ) return char;
-- 
--   procedure add_method (
--     content_type        in cm_content_type_method_map.content_type%TYPE,
--     content_method	in cm_content_type_method_map.content_method%TYPE,
--     is_default		in cm_content_type_method_map.is_default%TYPE
-- 			   default 'f'
--   );
-- 
--   procedure add_all_methods (
--     content_type	in cm_content_type_method_map.content_type%TYPE
--   );
-- 
--   procedure set_default_method ( 
--     content_type	in cm_content_type_method_map.content_type%TYPE,
--     content_method	in cm_content_type_method_map.content_method%TYPE
--   );
-- 
--   procedure unset_default_method (
--     content_type	in cm_content_type_method_map.content_type%TYPE
--   );
-- 
--   procedure remove_method (
--     content_type	in cm_content_type_method_map.content_type%TYPE,
--     content_method	in cm_content_type_method_map.content_method%TYPE
--   );
-- 
-- end content_method;

-- show errors





-- create or replace package body content_method as
-- function get_method
create or replace function content_method__get_method (varchar)
returns varchar as '
declare
  p_content_type                alias for $1;  
  v_method                      cm_content_type_method_map.content_method%TYPE;
  v_count                       integer;       
begin

    -- first, look for the default
    select
      content_method into v_method
    from
      cm_content_type_method_map
    where
      content_type = p_content_type
    and
      is_default = ''t'';

    if v_method is null then
      -- then check to see if there is only one registered content method
      select
        count( content_method ) into v_count
      from
        cm_content_type_method_map
      where
        content_type = p_content_type;

      if v_count = 1 then
        -- if so, return the only registered method
	select
	  content_method into v_method
	from
	  cm_content_type_method_map
	where
	  content_type = p_content_type;
      end if;      
    end if;

    return v_method;

--  exception 
--    when NO_DATA_FOUND then 
--      return null;
   
end;' language 'plpgsql';


-- function is_mapped
create or replace function content_method__is_mapped (varchar,varchar)
returns boolean as '
declare
  p_content_type          alias for $1;  
  p_content_method        alias for $2;  
begin
    
    return 
      count(*) > 0
    from
      cm_content_type_method_map
    where
      content_type = p_content_type
    and
      content_method = p_content_method;
   
end;' language 'plpgsql';


-- procedure add_method
create or replace function content_method__add_method (varchar,varchar,boolean)
returns integer as '
declare
  p_content_type                alias for $1;  
  p_content_method              alias for $2;  
  p_is_default                  alias for $3;  -- default ''f''
  v_method_already_mapped       integer;       
begin

    -- check if there is any existing mapping
    select
      count(1) into v_method_already_mapped
    from
      cm_content_type_method_map
    where
      content_type = p_content_type
    and
      content_method = p_content_method;

    if v_method_already_mapped = 1 then

      -- update the content type method mapping
      update cm_content_type_method_map
        set is_default = p_is_default
	where content_type = p_content_type
	and content_method = p_content_method;
    else
      -- insert the content type method mapping
      insert into cm_content_type_method_map (
        content_type, content_method, is_default
      ) values (
        p_content_type, p_content_method, 
	p_is_default
      );
    end if;

    return 0; 
end;' language 'plpgsql';


-- procedure add_all_methods
create or replace function content_method__add_all_methods (varchar)
returns integer as '
declare
  p_content_type    alias for $1;  
begin
    -- map all unmapped content methods to the content type 
    insert into cm_content_type_method_map (
      content_type, content_method, is_default
    ) select
      p_content_type as content_type, content_method, ''f''
    from
      cm_content_methods m
    where
      not exists (
        select 1
	from
	  cm_content_type_method_map
	where
	  content_method = m.content_method
        and
          content_type = p_content_type 
      );

      return 0; 
end;' language 'plpgsql';


-- procedure set_default_method
create or replace function content_method__set_default_method (varchar,varchar)
returns integer as '
declare
  p_content_type      alias for $1;  
  p_content_method    alias for $2;  
begin

    -- unset old default
    PERFORM content_method__unset_default_method (
        p_content_type
    );
    -- set new default
    update cm_content_type_method_map
      set is_default = ''t''
      where content_type = p_content_type
      and content_method = p_content_method;

    return 0; 
end;' language 'plpgsql';


-- procedure unset_default_method
create or replace function content_method__unset_default_method (varchar)
returns integer as '
declare
  p_content_type   alias for $1;  
begin

    update cm_content_type_method_map
      set is_default = ''f''
      where content_type = p_content_type;

    return 0; 
end;' language 'plpgsql';


-- procedure remove_method
create or replace function content_method__remove_method (varchar,varchar)
returns integer as '
declare
  p_content_type      alias for $1;  
  p_content_method    alias for $2;  
begin

    -- delete the content type - method mapping    
    delete from cm_content_type_method_map
      where content_type = p_content_type
      and content_method = p_content_method;

    return 0; 
end;' language 'plpgsql';



-- show errors
