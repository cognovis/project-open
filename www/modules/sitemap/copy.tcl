# Copy folders under another folder

request create 
request set_param id -datatype integer -optional
request set_param mount_point -datatype keyword -value sitemap


set root_id [cm::modules::${mount_point}::getRootFolderID]
if { [template::util::is_nil id] } {
  set folder_id $root_id
} else {
  set folder_id $id
}

# permission check - must have cm_new on the current folder
set user_id [User::getID]
content::check_access $folder_id cm_new -user_id $user_id 

set clip [clipboard::parse_cookie]
set clip_items [clipboard::get_items $clip $mount_point]
set clip_length [llength $clip_items]
if { $clip_length == 0 } {
    set no_items_on_clipboard "t"
    return
} else {
    set no_items_on_clipboard "f"
}

set path [db_string get_path ""]

# get relevant marked items
db_multirow marked_items get_marked ""

form create copy
element create copy mount_point \
	-datatype keyword \
	-widget hidden \
	-value $mount_point

element create copy id \
	-datatype integer \
	-widget hidden \
	-param \
	-optional

element create copy copied_items \
	-datatype integer \
	-widget checkbox

set marked_item_size [multirow size marked_items]

for { set i 1 } { $i <= $marked_item_size } { incr i } {
    set title [multirow get marked_items $i title]
    set name [multirow get marked_items $i name]
    set item_id [multirow get marked_items $i item_id]
    set parent_id [multirow get marked_items $i parent_id]
    
    element create copy "parent_id_$item_id" \
	    -datatype integer \
	    -widget hidden

    element set_value copy parent_id_$item_id $parent_id
}







if { [form is_valid copy] } {
    set user_id [User::getID]
    set ip [ns_conn peeraddr]

    form get_values copy id mount_point
    set copied_items [element get_values copy copied_items]

    db_transaction {

        set folder_flush_list [list]
        foreach cp_item_id $copied_items {
            set parent_id [element get_values copy "parent_id_$cp_item_id"]

            if { [catch {db_exec_plsql copy_item "
	    begin
            content_item.copy(
                item_id          => :cp_item_id,
                target_folder_id => :folder_id,
	        creation_user    => :user_id,
	        creation_ip      => :ip
            ); 
            end;"} errmsg] } {
                # possibly a duplicate name
                ns_log notice "ERROR: copy.tcl - while copying $errmsg"
            }

            # flush the cache
            if { [lsearch -exact $folder_flush_list $parent_id] == -1 } {
                lappend folder_flush_list $parent_id
                cms_folder::flush $mount_point $parent_id
            }

        }
    }

    # flush cache for destination folder
    if { $folder_id == [cm::modules::${mount_point}::getRootFolderID] } {
	set folder_id ""
    }
    cms_folder::flush $mount_point $folder_id
    clipboard::free $clip

    # Specify a null id so that the entire branch will be refreshed
    template::forward \
	    "refresh-tree?goto_id=$folder_id&mount_point=$mount_point"
}
