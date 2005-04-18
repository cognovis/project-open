# unpublish.tcl
# Publish a revision to the file system.

request create
request set_param item_id -datatype integer

publish::unpublish_item $item_id

db_transaction {
    db_exec_plsql unset_live_revision "begin 
           content_item.unset_live_revision( :item_id );
         end;"
}

template::forward "index?item_id=$item_id"
