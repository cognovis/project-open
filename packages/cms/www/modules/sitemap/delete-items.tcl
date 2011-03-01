# delete.tcl
# Delete marked items
request create 
request set_param id -datatype integer
request set_param mount_point -datatype keyword -value sitemap


set clip [clipboard::parse_cookie]
set clip_items [clipboard::get_items $clip $mount_point]
set clip_length [llength $clip_items]
if { $clip_length == 0 } {
    set no_items_on_clipboard "t"
    return
} else {
    set no_items_on_clipboard "f"
}

set user_id [User::getID]

# get title, content_type, path, item_id of each marked item

db_multirow marked_items get_marked_items ""


form create delete

element create delete deleted_items \
	-datatype integer \
	-widget checkbox

set marked_item_size [multirow size marked_items]

for { set i 1 } { $i <= $marked_item_size } { incr i } {
    set item_id [multirow get marked_items $i item_id]
    set is_symlink [multirow get marked_items $i is_symlink]
    set is_folder [multirow get marked_items $i is_folder]
    set is_template [multirow get marked_items $i is_template]

    element create delete "is_symlink_$item_id" \
	    -datatype keyword \
	    -widget hidden \
	    -value $is_symlink

    element create delete "is_folder_$item_id" \
	    -datatype keyword \
	    -widget hidden \
	    -value $is_folder

    element create delete "is_template_$item_id" \
	    -datatype keyword \
	    -widget hidden \
	    -value $is_template
}





if { [form is_valid delete] } {

    set user_id [User::getID]
    set ip [ns_conn peeraddr]

    set deleted_items [element get_values delete deleted_items]

    db_transaction {

        set parents [list]
        foreach del_item_id $deleted_items {
            set is_symlink [element get_values delete "is_symlink_$del_item_id"]
            set is_folder [element get_values delete "is_folder_$del_item_id"]
            set is_template [element get_values delete "is_template_$del_item_id"]

            # get all the parent_id's of the items being deleted
            #   because we need to flush the paginator cache for each of 
            #   these folders
            set flush_list [db_list get_list ""]

            # set up the call to the proper PL/SQL delete procedure
            if { [string equal $is_symlink "t"] } {
                set delete_proc [db_map symlink_delete]
                set delete_key "symlink_id"
            } elseif { [string equal $is_folder "t"] } {
                set delete_proc [db_map folder_delete]
                set delete_key "folder_id"   
            } elseif { [string equal $is_template "t"] } {
                set delete_proc [db_map template_delete]
                set delete_key "template_id"
            } else {
                set delete_proc [db_map item_delete]
                set delete_key "item_id"
            }

            # the following SQL will have this form:
            # content_something.delete(
            #   something_id => :del_item_id
            # );

            if { [catch { db_exec_plsql delete_items "
	  begin
	  $delete_proc (
	    $delete_key => :del_item_id
          );
          end;" } errmsg] } {
                ns_log notice \
                    "../../sitemap/delete.tcl caught error in dml: - $errmsg"
                ns_log notice \
                    "../../sitemap/delete.tcl - Item $del_item_id was not deleted"
            }

            # build a list of parent items whose paginator cache needs flushing
            foreach parent_id $flush_list {
                # flush as few times as necessary
                if { [lsearch -exact $parents $parent_id] == -1 } {
                    # flush cache
                    lappend parents $parent_id

                    if { $parent_id == [cm::modules::${mount_point}::getRootFolderID] } {
                        set parent_id ""
                    }
                    cms_folder::flush $mount_point $parent_id

                }
            }
        }
    }

    clipboard::free $clip

    # Specify a null id so that the entire branch will be refreshed
    forward "refresh-tree?goto_id=$id&id=$id&mount_point=$mount_point"
}
