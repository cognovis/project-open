# /types/unregister-mime-type.tcl
# Unregister a MIME type to a content type


request create
request set_param content_type -datatype keyword
request set_param mime_type -datatype text


db_transaction {

    set module_id [db_string get_module_id ""]

    # permissions check - must have cm_write to unregister mime type
    content::check_access $module_id cm_write -user_id [User::getID]

    db_exec_plsql unregister_mime_type "
  begin
    content_type.unregister_mime_type(
        content_type => :content_type,
        mime_type    => :mime_type
    );
  end;"
}

content_method::flush_content_methods_cache $content_type

template::forward "index?id=$content_type"
