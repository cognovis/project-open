# Add a template of the item

request create
request set_param item_id -datatype integer
request set_param template_id -datatype integer
request set_param context -datatype keyword


db_transaction {

    # check to make sure that no template is already registered
    #   to this item in this context
    set second_template_p [db_string second_template_p ""]

    if { $second_template_p == 0 } {
        if { [catch { db_exec_plsql register_template_to_item "begin content_item.register_template(
            item_id     => :item_id,
            template_id => :template_id,
            use_context => :context ); 
         end;"} err_msg] } {
            ns_log notice "template-register.tcl got an error: $err_msg"
        }
    }
}

forward "../items/index?item_id=$item_id&#templates"
