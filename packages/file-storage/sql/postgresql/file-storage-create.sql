--
-- file-storage/sql/postgresql/file-storage-create.sql
--
-- @author Kevin Scaldeferri (kevin@arsdigita.com)
-- @creation-date 6 Nov 2000
-- @cvs-id $Id$
--

-- JS: I changed the way file storage uses the CR:  cr_items will store
-- JS: a file's meta-data, while cr_revisions will store specifics of a
-- JS: file's version.  Every file has at least one version.
-- JS:
-- JS: 1) The name attribute in cr_items will store the "title" of the 
-- JS:     of the file, and all its versions. 
-- JS:
-- JS: 2) The title attribute in cr_revisions  will store the filename 
-- JS: of each version, which may be different among versions of the same title.
-- JS:
-- JS: 3)   Version notes will still be stored in the description attribute. 
-- JS:
-- JS: The unfortunate result is that the use of "title" and "name" in 
-- JS: cr_revisions and cr_items, respectively, are interchanged.
-- JS:

--
-- We need to create a root folder in the content repository for 
-- each instance of file storage
--
create table fs_root_folders (
    -- ID for this package instance
    package_id  integer
                constraint fs_root_folder_package_id_fk
                references apm_packages on delete cascade
                constraint fs_root_folder_package_id_pk
                primary key,
    -- the ID of the root folder
    -- JS: I removed the on delete cascade constraint on folder_id
    -- JS: It is superfluous, and causes a lot of RI headaches
    -- DAVEB: I put it back. I have no idea what JS is referring to.
    -- DAVEB: If you ever want to delete a root folder, say by deleting a
    -- DAVEB: package instance of file-storage, you need this.
    -- DAVEB: You DO have to delete all the folder contents and use CR pl/sql
    -- DAVEB: procs to delete the folder, when you do that the on delete
    -- DAVEB: cascade works fine.
    folder_id   integer
                constraint fs_root_folder_folder_id_fk
                references cr_folders on delete cascade
                constraint fs_root_folder_folder_id_un
                unique
);





-- fraber 110228
-- There is an error in the old CR creation apparently...

create or replace function content_type__create_type (varchar,varchar,varchar,varchar,varchar,varchar,varchar)
returns integer as '
declare
  create_type__content_type           alias for $1;  
  create_type__supertype              alias for $2;  -- default ''content_revision''  
  create_type__pretty_name            alias for $3;  
  create_type__pretty_plural          alias for $4;  
  create_type__table_name             alias for $5;
  create_type__id_column              alias for $6;  -- default ''XXX''
  create_type__name_method            alias for $7;  -- default null
  v_temp_p                            boolean;       
  v_supertype_table                   acs_object_types.table_name%TYPE;
                                        
begin

  if (create_type__supertype <> ''content_revision'')
      and (create_type__content_type <> ''content_revision'') then
    select count(*) > 0 into v_temp_p
    from  acs_object_type_supertype_map
    where object_type = create_type__supertype
    and ancestor_type = ''content_revision'';

    if not v_temp_p then
      raise EXCEPTION ''-20000: supertype % must be a subtype of content_revision'', create_type__supertype;
    end if;
  end if;

  select count(*) > 0 into v_temp_p from pg_class
   where relname = lower(create_type__table_name);

  if NOT v_temp_p and create_type__table_name is not null then
    select table_name into v_supertype_table from acs_object_types
      where object_type = create_type__supertype;

    raise NOTICE ''content_type__create_type: table_name=%, id_column=%, supertype_table=%'', 
	create_type__table_name, create_type__id_column, v_supertype_table;

    execute ''create table '' || create_type__table_name || '' ('' ||
      create_type__id_column || '' integer constraint '' || create_type__table_name || ''_pk primary key '' || 
      '' constraint '' || create_type__table_name || ''_fk references '' || v_supertype_table || '')'';
  end if;

  PERFORM acs_object_type__create_type (
    create_type__content_type,
    create_type__pretty_name,
    create_type__pretty_plural,
    create_type__supertype,
    create_type__table_name,
    create_type__id_column,
    null,
    ''f'',
    null,
    create_type__name_method
  );

  PERFORM content_type__refresh_view(create_type__content_type);

  return 0; 
end;' language 'plpgsql';



-- Create a subtype of content_revision so that site-wide-search can
-- distinguish file-storage items (v.s. generic content repository
-- items) in the search results
select content_type__create_type (
       'file_storage_object',    -- content_type
       'content_revision',       -- supertype. We search revision content 
                                 -- first, before item metadata
       'File Storage Object',    -- pretty_name
       'File Storage Objects',   -- pretty_plural
       NULL,        -- table_name
       -- DAVEB: acs_object_types supports a null table name so we do that
       -- instead of passing a false value so we can actually use the
       -- content repository instead of duplicating all the code in file-storage
       NULL,	         -- id_column
       'file_storage__get_title' -- name_method
);

create or replace function inline_0 ()
returns integer as'
declare
    template_id integer;
begin

    -- Create the (default) file_storage_object content type template

    template_id := content_template__new( 
      ''file-storage-default'', -- name
      ''<master>
<property name="title">@title;noquote@</property>
<property name="context">@context;noquote@</property>
<property name="displayed_object_id">@item_id;noquote@</property>
@text;noquote@'',               -- text
      true                      -- is_live
    );

    -- Register the template for the file_storage_object content type

    perform content_type__register_template(
      ''file_storage_object'', -- content_type
      template_id,             -- template_id
      ''public'',              -- use_context
      ''t''                    -- is_default
    );

    return null;
end;' language 'plpgsql';

select inline_0();
drop function inline_0();


\i file-storage-package-create.sql

\i file-storage-views-create.sql

\i file-storage-notifications-create.sql

\i file-storage-rss-create.sql
