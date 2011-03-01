# register content types from clipboard to a folder

request create
request set_param folder_id -datatype integer


set clip [clipboard::parse_cookie]
set marked_types [clipboard::get_items $clip "types"]
    
db_transaction {
    foreach type $marked_types {

        db_exec_plsql register_type "begin
           content_folder.register_content_type(
               folder_id        => :folder_id,
               content_type     => :type,
               include_subtypes => 'f'
           );
         end;"
    }
}

cms_folder::flush_registered_types $folder_id

clipboard::free $clip

forward "attributes?folder_id=$folder_id"
