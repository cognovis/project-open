# /packages/views/tcl/views-procs.tcl
ad_library {
    TCL library for recoding views

    @author Jeff Davis <davis@xarg.net>

    @creation-date 2004-05-20
    @cvs-id $Id: views-procs.tcl,v 1.6 2007/08/02 08:33:39 marioa Exp $
}

namespace eval views {}

ad_proc -public views::record_view {
    -object_id
    -viewer_id
    {-type ""}
} {
    Record an object view by viewer_id

    @param dimension_key
    @param object_id 

    @return the total view count for the user

    @author Jeff Davis davis@xarg.net
    @creation-date 2004-01-30
} {
    if { $type ne "" } {
	if { [lsearch [list views_count unique_views last_viewed] $type] >= 0 } {
	    # if the type is on of the list it will conflict on the views::get procedure
	    error "views::record_view type cannot be views_count, unique_views or last_viewed"
	}
	#TYPE is PL/SQL reserver word in ORACLE
	#set view_type $type
	set views_by_type [db_exec_plsql record_view_by_type {}]
    }

    if {[catch {set views [db_exec_plsql record_view {}]} views]} {
		set views 0
    }
    return $views
}

ad_proc -public views::get { 
    -object_id
} {

    Return an array (which you have to set with "array set your_array [views::get -object_id $object_id]") with the elements:
    <ul>
    <li>views_count
    <li>unique_views
    <li>last_viewed
    </ul>
    
    @param object_id ID of the object for which you want to return the views
} {
    if {[db_0or1row views { } -column_array ret] } {
        db_foreach select_views_by_type { } {
	    set ret($view_type) $views_count
	}
        return [array get ret]
    }
    return {views_count {} unique_views {} last_viewed {}}
}


ad_proc -public views::viewed_p { 
    -object_id
    {-user_id 0}
    {-type ""}
} {
    if {!$user_id} {
        set user_id [ad_conn user_id]
    }
    if { $type ne "" } {
		return [db_string get_viewed_by_type_p { } -default 0]
    } else {
		return [db_string get_viewed_p { } -default 0]
    }

}
