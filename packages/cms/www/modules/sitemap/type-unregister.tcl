# unregister a content type to a folder

request create
request set_param folder_id -datatype keyword
request set_param type_key -datatype keyword



db_transaction {
    db_exec_plsql unregister "
         begin
           content_folder.unregister_content_type(
               folder_id        => :folder_id,
               content_type     => :type_key,
               include_subtypes => 'f' 
           );
         end;"
}

cms_folder::flush_registered_types $folder_id

forward "attributes?folder_id=$folder_id"
