-- Add user_id and IP to update_last_modified
-- $Id

create or replace function file_storage__new_file(
       -- 
       -- Create a file in CR in preparation for actual storage
       -- Wrapper for content_item__new
       --
       -- DRB: I added this version to allow one to predefine item_id, among other things to
       -- make it easier to use with ad_form
       varchar,         -- cr_items.name%TYPE,
       integer,         -- cr_items.parent_id%TYPE,
       integer,         -- acs_objects.creation_user%TYPE,
       varchar,         -- acs_objects.creation_ip%TYPE,
       boolean,         -- store in db? 
       integer          -- cr_items.item_id%TYPE,
) returns integer as ' -- cr_items.item_id%TYPE
declare
        new_file__title                 alias for $1;
        new_file__folder_id             alias for $2;
        new_file__user_id               alias for $3;
        new_file__creation_ip           alias for $4;
        new_file__indb_p                alias for $5;
        new_file__item_id               alias for $6;
        v_item_id                       integer;
begin

        if new_file__indb_p
        then 
            v_item_id := content_item__new (
                        new_file__title,            -- name
                        new_file__folder_id,      -- parent_id
                        new_file__item_id,        -- item_id (default)
                        null,                       -- locale (default)
                        now(),              -- creation_date (default)
                        new_file__user_id,        -- creation_user
                        new_file__folder_id,      -- context_id
                        new_file__creation_ip,    -- creation_ip
                        ''content_item'',         -- item_subtype (default)
                        ''file_storage_object'',  -- content_type (needed by site-wide search)
                        null,                       -- title (default)
                        null,                       -- description
                        ''text/plain'',     -- mime_type (default)
                        null,                       -- nls_language (default)
                        null                        -- data (default)
                    );
        else
            v_item_id := content_item__new (
                        new_file__title,            -- name
                        new_file__folder_id,        -- parent_id
                        new_file__item_id,          -- item_id (default)
                        null,                       -- locale (default)
                        now(),              -- creation_date (default)
                        new_file__user_id,          -- creation_user
                        new_file__folder_id,        -- context_id
                        new_file__creation_ip,    -- creation_ip
                        ''content_item'',         -- item_subtype (default)
                        ''file_storage_object'',  -- content_type (needed by site-wide search)
                        null,                       -- title (default)
                        null,                       -- description
                        ''text/plain'',     -- mime_type (default)
                        null,                       -- nls_language (default)
                        null,                       -- text (default)
                        ''file''                    -- storage_type
                    );

        end if;

        perform acs_object__update_last_modified(new_file__folder_id,new_file__user_id,new_file__creation_ip);

        return v_item_id;

end;' language 'plpgsql';
    

create or replace function file_storage__copy_file(
       --
       -- Copy a file, but only copy the live_revision
       --
       integer,         -- cr_items.item_id%TYPE,
       integer,         -- cr_items.parent_id%TYPE,
       integer,         -- acs_objects.creation_user%TYPE,
       varchar          -- acs_objects.creation_ip%TYPE
) returns integer as '  -- cr_revisions.revision_id%TYPE 
declare
        copy_file__file_id           alias for $1;
        copy_file__target_folder_id  alias for $2;
        copy_file__creation_user     alias for $3;
        copy_file__creation_ip       alias for $4;
        v_title                      cr_items.name%TYPE;
        v_live_revision              cr_items.live_revision%TYPE;
        v_filename                   cr_revisions.title%TYPE;
        v_description                cr_revisions.description%TYPE;
        v_mime_type                  cr_revisions.mime_type%TYPE;
        v_content_length             cr_revisions.content_length%TYPE;
        v_lob_id                     cr_revisions.lob%TYPE;
        v_new_lob_id                 cr_revisions.lob%TYPE;
        v_file_path                  cr_revisions.content%TYPE;
        v_new_file_id                cr_items.item_id%TYPE;
        v_new_version_id                     cr_revisions.revision_id%TYPE;
        v_indb_p                     boolean;
begin

        -- We copy only the title from the file being copied, and attributes of the
        -- live revision
        select i.name,i.live_revision,r.title,r.description,r.mime_type,r.content_length,
               (case when i.storage_type = ''lob''
                     then true
                     else false
                end)
               into v_title,v_live_revision,v_filename,v_description,v_mime_type,v_content_length,v_indb_p
        from cr_items i, cr_revisions r
        where r.item_id = i.item_id
        and   r.revision_id = i.live_revision
        and   i.item_id = copy_file__file_id;

        -- We should probably use the copy functions of CR
        -- when we optimize this function
        v_new_file_id := file_storage__new_file(
                             v_title,                     -- title
                             copy_file__target_folder_id, -- folder_id
                             copy_file__creation_user,    -- creation_user
                             copy_file__creation_ip,      -- creation_ip
                             v_indb_p                     -- indb_p
                             );

        v_new_version_id := file_storage__new_version (
                             v_filename,                  -- title
                             v_description,               -- description
                             v_mime_type,                 -- mime_type
                             v_new_file_id,               -- item_id
                             copy_file__creation_user,    -- creation_user
                             copy_file__creation_ip       -- creation_ip
                             );
                             
        if v_indb_p
        then

                -- Lob to copy from
                select lob into v_lob_id
                from cr_revisions
                where revision_id = v_live_revision;

                -- New lob id
                v_new_lob_id := empty_lob();

                -- copy the blob
                perform lob_copy(v_lob_id,v_new_lob_id);

                -- Update the lob id on the new version
                update cr_revisions
                set lob = v_new_lob_id,
                    content_length = v_content_length
                where revision_id = v_new_version_id;

        else

                -- For now, we simply copy the file name
                select content into v_file_path
                from cr_revisions
                where revision_id = v_live_revision;

                -- Update the file path
                update cr_revisions
                set content = v_file_path,
                    content_length = v_content_length
                where revision_id = v_new_version_id;

        end if;

        perform acs_object__update_last_modified(copy_file__target_folder_id,copy_file__creation_user,copy_file__creation_ip);

        return v_new_version_id;

end;' language 'plpgsql';


create or replace function file_storage__move_file (
       --
       -- Move a file (ans all its versions) to a different folder.
       -- Wrapper for content_item__move
       -- 
       integer,         -- cr_folders.folder_id%TYPE,
       integer,          -- cr_folders.folder_id%TYPE
       integer,
       varchar
) returns integer as '  -- 0 for success 
declare
        move_file__file_id              alias for $1;
        move_file__target_folder_id     alias for $2;
        move_file__creation_user        alias for $3;
        move_file__creation_ip          alias for $4;
begin

        perform content_item__move(
               move_file__file_id,              -- item_id
               move_file__target_folder_id      -- target_folder_id
               );

        perform acs_object__update_last_modified(move_file__target_folder_id,move_file__creation_user,move_file__creation_ip);

        return 0;
end;' language 'plpgsql';

create or replace function file_storage__new_version (
       --
       -- Create a new version of a file
       -- Wrapper for content_revision__new
       --
       varchar,         -- cr_revisions.title%TYPE,
       varchar,         -- cr_revisions.description%TYPE,
       varchar,         -- cr_revisions.mime_type%TYPE,
       integer,         -- cr_items.item_id%TYPE,
       integer,         -- acs_objects.creation_user%TYPE,
       varchar          -- acs_objects.creation_ip%TYPE
) returns integer as '  -- cr_revisions.revision_id 
declare
        new_version__filename           alias for $1;
        new_version__description        alias for $2;
        new_version__mime_type          alias for $3;
        new_version__item_id            alias for $4;
        new_version__creation_user      alias for $5;
        new_version__creation_ip        alias for $6;
        v_revision_id                   cr_revisions.revision_id%TYPE;
        v_folder_id                     cr_items.parent_id%TYPE;
begin
        -- Create a revision
        v_revision_id := content_revision__new (
                          new_version__filename,        -- title
                          new_version__description,     -- description
                          now(),                        -- publish_date
                          new_version__mime_type,       -- mime_type
                          null,                         -- nls_language
                          null,                         -- data (default)
                          new_version__item_id,         -- item_id
                          null,                         -- revision_id
                          now(),                        -- creation_date
                          new_version__creation_user,   -- creation_user
                          new_version__creation_ip      -- creation_ip
                          );

        -- Make live the newly created revision
        perform content_item__set_live_revision(v_revision_id);

        select cr_items.parent_id
        into v_folder_id
        from cr_items
        where cr_items.item_id = new_version__item_id;

        perform acs_object__update_last_modified(v_folder_id,new_version__creation_user,new_version__creation_ip);

        return v_revision_id;

end;' language 'plpgsql';

