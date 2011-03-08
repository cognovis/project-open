# publish.tcl
# Publish a revision to the file system.

request create
request set_param revision_id -datatype integer

set root_path [ns_info pageroot]

db_transaction {

    db_1row get_iteminfo ""

    if { [string equal $publish_p t] } {

        # publish::publish_revision $revision_id

        db_exec_plsql set_live_revision "
     begin 
       content_item.set_live_revision( 
         revision_id => :revision_id 
       );
     end;" 

        publish::unpublish_item $item_id
        
    } else {

        db_abort_transaction

        set msg "This item is not in a publishable state" 
        set return_url "index?item_id=$item_id"
        set passthrough { { item_id $item_id } }

        content::show_error $msg $return_url $passthrough
    }
}

template::forward "index?item_id=$item_id"
