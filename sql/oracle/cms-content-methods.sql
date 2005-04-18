/* 
   cms-content-method.sql

   @author Michael Pih

   Data model and package definitions for mapping content types 
   to content methods
*/



/* Data model *?

/* Means of inserting content into the database. */
create table cm_content_methods (
  content_method	varchar2(100)
			constraint cm_content_methods_pk
			primary key,
  label			varchar2(100) not null,
  description		varchar2(4000)			
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
  content_type		varchar2(100)
			constraint cm_type_method_map_type_fk
			references acs_object_types,
  content_method	varchar2(100) default 'no_content'
			constraint cm_type_method_map_method_fk
			references cm_content_methods,
  is_default		char(1) 
			constraint cm_method_map_is_default_ck
			check (is_default in ('t','f'))
);


/* A view of all mapped content methods */
create or replace view cm_type_methods
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

create or replace package content_method as

  function get_method (
    content_type        in cm_content_type_method_map.content_type%TYPE
  ) return cm_content_type_method_map.content_method%TYPE;

  function is_mapped ( 
    content_type        in cm_content_type_method_map.content_type%TYPE,
    content_method	in cm_content_type_method_map.content_method%TYPE
  ) return char;

  procedure add_method (
    content_type        in cm_content_type_method_map.content_type%TYPE,
    content_method	in cm_content_type_method_map.content_method%TYPE,
    is_default		in cm_content_type_method_map.is_default%TYPE
			   default 'f'
  );

  procedure add_all_methods (
    content_type	in cm_content_type_method_map.content_type%TYPE
  );

  procedure set_default_method ( 
    content_type	in cm_content_type_method_map.content_type%TYPE,
    content_method	in cm_content_type_method_map.content_method%TYPE
  );

  procedure unset_default_method (
    content_type	in cm_content_type_method_map.content_type%TYPE
  );

  procedure remove_method (
    content_type	in cm_content_type_method_map.content_type%TYPE,
    content_method	in cm_content_type_method_map.content_method%TYPE
  );

end content_method;
/
show errors





create or replace package body content_method as

  function get_method (
    content_type        in cm_content_type_method_map.content_type%TYPE
  ) return cm_content_type_method_map.content_method%TYPE
  is
    v_method	cm_content_type_method_map.content_method%TYPE;
    v_count	integer;
  begin

    -- first, look for the default
    select
      content_method into v_method
    from
      cm_content_type_method_map
    where
      content_type = get_method.content_type
    and
      is_default = 't';

    if v_method is null then
      -- then check to see if there is only one registered content method
      select
        count( content_method ) into v_count
      from
        cm_content_type_method_map
      where
        content_type = get_method.content_type;

      if v_count = 1 then
        -- if so, return the only registered method
	select
	  content_method into v_method
	from
	  cm_content_type_method_map
	where
	  content_type = get_method.content_type;
      end if;      
    end if;

    return v_method;
  exception 
    when NO_DATA_FOUND then 
      return null;
  end get_method;

  function is_mapped ( 
    content_type        in cm_content_type_method_map.content_type%TYPE,
    content_method	in cm_content_type_method_map.content_method%TYPE
  ) return char
  is
    v_is_mapped		char(1);
  begin
    
    select
      't' into v_is_mapped
    from
      cm_content_type_method_map
    where
      content_type = is_mapped.content_type
    and
      content_method = is_mapped.content_method;

    return v_is_mapped;
    exception
      when NO_DATA_FOUND then
        return 'f';
  end is_mapped;

  procedure add_method (
    content_type        in cm_content_type_method_map.content_type%TYPE,
    content_method	in cm_content_type_method_map.content_method%TYPE,
    is_default		in cm_content_type_method_map.is_default%TYPE
			   default 'f'
  ) is
    v_method_already_mapped integer;
  begin

    -- check if there is any existing mapping
    select
      count(1) into v_method_already_mapped
    from
      cm_content_type_method_map
    where
      content_type = add_method.content_type
    and
      content_method = add_method.content_method;

    if v_method_already_mapped = 1 then

      -- update the content type method mapping
      update cm_content_type_method_map
        set is_default = add_method.is_default
	where content_type = add_method.content_type
	and content_method = add_method.content_method;
    else
      -- insert the content type method mapping
      insert into cm_content_type_method_map (
        content_type, content_method, is_default
      ) values (
        add_method.content_type, add_method.content_method, 
	add_method.is_default
      );
    end if;
  end add_method;

  procedure add_all_methods (
    content_type	in cm_content_type_method_map.content_type%TYPE
  ) is
  begin
    -- map all unmapped content methods to the content type 
    insert into cm_content_type_method_map (
      content_type, content_method, is_default
    ) select
      add_all_methods.content_type, content_method, 'f'
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
          content_type = add_all_methods.content_type 
      );
  end add_all_methods;

  procedure set_default_method ( 
    content_type	in cm_content_type_method_map.content_type%TYPE,
    content_method	in cm_content_type_method_map.content_method%TYPE
  ) is
  begin

    -- unset old default
    unset_default_method (
        content_type => set_default_method.content_type
    );
    -- set new default
    update cm_content_type_method_map
      set is_default = 't'
      where content_type = set_default_method.content_type
      and content_method = set_default_method.content_method;
  end set_default_method;

  procedure unset_default_method (
    content_type	in cm_content_type_method_map.content_type%TYPE
  ) is
  begin

    update cm_content_type_method_map
      set is_default = 'f'
      where content_type = unset_default_method.content_type;
  end unset_default_method;

  procedure remove_method (
    content_type	in cm_content_type_method_map.content_type%TYPE,
    content_method	in cm_content_type_method_map.content_method%TYPE
  ) is
  begin

    -- delete the content type - method mapping    
    delete from cm_content_type_method_map
      where content_type = remove_method.content_type
      and content_method = remove_method.content_method;
  end remove_method;

end content_method;
/
show errors
