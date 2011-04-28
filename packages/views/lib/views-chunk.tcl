# packages/views/lib/views-chunk.tcl
#
# shows views
#
# @author Deds Castillo (deds@i-manila.com.ph)
# @creation-date 2004-08-03
# @arch-tag: c2038e8f-832a-4d9c-913b-6fbd5d429375
# @cvs-id $Id: views-chunk.tcl,v 1.3 2007/08/02 08:32:10 marioa Exp $

foreach required_param {package_id object_type} {
    if {![info exists $required_param]} {
        return -code error "$required_param is a required parameter."
    }
}

foreach optional_param {filter_url} {
    if {![info exists $optional_param]} {
        set $optional_param {}
    }
}

if {![info exists sortby]} {
    set sortby viewer_name
}

set user_id [ad_conn user_id]
set admin_p [permission::permission_p -object_id $package_id -party_id $user_id -privilege admin]


if {!$admin_p} {
    set viewer_id $user_id
    set user_filter_label ""
} else {
    if {[info exists viewer_id]} {
        if {![empty_string_p $viewer_id]} {
            set user_filter_label [acs_user::get_element -user_id $viewer_id -element name]
        } else {
            set user_filter_label All
            unset viewer_id
        }
    } else {
        set user_filter_label All
    }
}

set elements_list {
    object_type_pretty_name {
        label "Type"
    }
    object_name {
        label "Title"
    }
    viewer_name {
        label "User Name"
        display_col fullname
    }
    total_views {
        label "\# of Times Viewed"
    }
    pretty_last_viewed {
        label "Last Viewed On"
    }
}

set orderby_list {
    viewer_name {
        orderby_asc {lower(last_name) asc,lower(first_names) asc, lower(object_name) asc}
        orderby_desc {lower(last_name) desc,lower(first_names) desc, lower(object_name) desc}
    }
    object_name {
        orderby object_name
    }
    total_views {
        orderby total_views
    }
    pretty_last_viewed {
        orderby last_viewed
    }
}

set filters_list {
    sortby {
        hide_p 1
    }
    viewer_id {
        label "Show User"
        where_clause {viewing_user_id = :viewer_id}
        other_label $user_filter_label
        has_default_p 1
    }
    object_id {
        where_clause {object_id = :object_id}
    }
}

acs_object_type::get -object_type $object_type -array one_object_type

template::list::create \
    -name views \
    -multirow views \
    -elements $elements_list \
    -orderby $orderby_list \
    -orderby_name sortby \
    -filters $filters_list
    
set orderby_clause [template::list::orderby_clause -orderby -name views]
set where_clause [template::list::filter_where_clauses -name views -and]

# DEDS: the acs_object__name call fscks up the execution time
# though in this case we just want to showcase this as proof of
# concept anyway.  the partial solution is already in HEAD but we are
# not using that.  See: http://openacs.org/forums/message-view?message_id=158875

db_multirow -extend {fullname object_type_pretty_name viewer_id_filter_link} views select_views {} {
    set object_type_pretty_name $one_object_type(pretty_name)
    set fullname "$first_names $last_name"
    if {$admin_p} {
        set viewer_id_filter_link [export_vars -base $filter_url {{viewer_id $viewing_user_id} sortby}]
    } else {
        set viewer_id_filter_link ""
    }
}
