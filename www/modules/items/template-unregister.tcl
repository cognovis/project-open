# Add a template of the item

request create
request set_param item_id -datatype integer
request set_param template_id -datatype integer
request set_param context -datatype text


db_transaction {
    if { [catch { db_exec_plsql template_unregister "begin
         content_item.unregister_template(
             template_id => :template_id, 
             item_id     => :item_id, 
             use_context => :context ); 
         end;" } err_msg] } {
        ns_log notice "template-remove.tcl got an error: $err_msg"
    }
}

template::forward "../items/index?item_id=$item_id&#templates"
