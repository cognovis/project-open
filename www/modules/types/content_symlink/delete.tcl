# Delete a content symlink

template::request create
template::request set_param id -datatype keyword
template::request set_param parent_id -datatype keyword -optional

db_transaction {
    db_exec_plsql symlink_delete "
         begin content_symlink.del(:id); end;" 
}

template::forward "../../sitemap/refresh-tree?id=$parent_id"
