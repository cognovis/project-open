##########################
#
# Procedures to manipulate the clipboard
#
################

namespace eval clipboard {   
  # See clipboard-ui-procs.tcl
  namespace eval ui {}
}
  
ad_proc -public clipboard::parse_cookie {} { 

    Get the clipboard from a cookie and return it

} {
    set clipboard_cookie [template::util::get_cookie content_marks]   
    ns_log debug "clipboard::parse_cookie: cookie $clipboard_cookie"
    set clip [ns_set create]
    set mount_branches [split $clipboard_cookie "|"]
    set mount_points [list]
    set total_items 0
    
    foreach branch $mount_branches {
        if { [regexp {([a-zA-Z0-9]+):(.*)} $branch match mount_point items] } {
            ns_log debug "clipboard::parse_cookie: branch: $branch"
            set items_list [split $items ","]  
            set items_size [llength $items_list]
            incr total_items $items_size
            ns_set update $clip $mount_point $items_list
            ns_set update $clip ${mount_point}_size $items_size
            lappend mount_points $mount_point
        }
    }

    ns_set put $clip __total_items__ $total_items
    ns_set put $clip __mount_points__ $mount_points
    
    return $clip
}

ad_proc -public clipboard::get_items { clip mount_point } {

  Retreive all marked items as a list

} {
    return [ns_set get $clip $mount_point]
}

ad_proc -public clipboard::get_total_items { clip } {

  Get the number of total items on the clipboard

} {
    return [ns_set get $clip __total_items__]
}

ad_proc -public clipboard::map_code { clip mount_point code } {

  Execute a piece of code for each item under the
  specified mount point, creating an item_id
  variable for each item id

} {
    set item_id_list [ns_set get $clip $mount_point]
    foreach id $item_id_list {
        uplevel "set item_id $id; $code"
    }
}

ad_proc -public clipboard::is_marked { clip mount_point item_id } {

  Determine if an item is marked

} {
    if { [lsearch -exact \
              [get_items $clip $mount_point] \
              $item_id] > -1} { 
        return 1
    } else {
        return 0
    }
}

ad_proc -public clipboard::get_bookmark_icon { clip mount_point item_id {row_ref row} } {

  Use this function as part of the multirow query to
  set up the bookmark icon

} {
    upvar $row_ref row

    if { [clipboard::is_marked $clip $mount_point $item_id] } {
        set row(bookmark) Bookmarked
    } else {
        set row(bookmark) Bookmarks
    }

    return $row(bookmark)
}

ad_proc -public clipboard::add_item { clip mount_point item_id } {

  Add an item to the clipboard: BROKEN

} {
    set old_items [ns_set get $clip $mount_point]
    if { [lsearch $old_items $item_id] == -1 } {

        # Append the item
        lappend old_items $item_id
        ns_set update $clip $mount_point $old_items
        ns_set update $clip ${mount_point}_size \
            [expr [ns_set get $clip ${mount_point}_size] + 1]
        ns_set update $clip __total_items__ \
            [expr [ns_set get $clip __total_items__] + 1]
        
        # Append the mount point
        set old_mount_points [ns_set get $clip __mount_points__]
        if { [lsearch -exact $old_mount_points $mount_point] == -1 } {
            lappend old_mount_points $mount_point
            ns_set update $clip __mount_points__ $old_mount_points
        }
    }
}

ad_proc -public clipboard::remove_item { clip mount_point item_id } {

  Remove an item from the clipboard: BROKEN

} {
    set old_items [ns_set get $clip $mount_point]
    set index [lsearch $old_items $item_id]
    if { $index !=  -1 } {

        # Remove the item
        set old_items [lreplace $old_items $index $index ""]
        ns_set update $clip $mount_point $old_items
        ns_set update $clip ${mount_point}_size \
            [expr [ns_set get $clip ${mount_point}_size] - 1]
        ns_set update $clip __total_items__ \
            [expr [ns_set get $clip __total_items__] - 1]
    }
}

ad_proc -public clipboard::set_cookie { clip } {

  Actually set the new cookie: BROKEN

} {
    set the_cookie ""
    set mount_point_names [ns_set get $clip __mount_points__] 
    set pipe ""
    foreach mount_point $mount_point_names {
        append the_cookie "$pipe${mount_point}:[join [ns_set get $clip $mount_point] ,]"
        set pipe "|"
    }

    template::util::set_cookie session content_marks $the_cookie
}

ad_proc -public clipboard::clear_cookie {} {

  Clear the clipboard: BROKEN

} {
    template::util::clear_cookie content_marks
}

ad_proc -public clipboard::free { clip } {

  Release the resources associated with the clipboard

} {
    ns_set free $clip
}

ad_proc -public clipboard::floats_p {} {

  determines whether clipboard should float or not
  currently incomplete, should be checking user prefs

} {
    return [ad_parameter ClipboardFloatsP]

}



 
  
   
