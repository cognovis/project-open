ad_library {
    Implementations of various service contracts.
    
    @creation-date 13 January 2003
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval workflow::impl {}

namespace eval workflow::impl::role_default_assignees {}
namespace eval workflow::impl::role_default_assignees::creation_user {}
namespace eval workflow::impl::role_default_assignees::static_assignees {}

namespace eval workflow::impl::role_assignee_pick_list {}
namespace eval workflow::impl::role_assignee_pick_list::current_assignees {}

namespace eval workflow::impl::role_assignee_subquery {}
namespace eval workflow::impl::role_assignee_subquery::registered_users {}

namespace eval workflow::impl::notification {}

#####
#
# Generic service contract implementation procs
#
#####

ad_proc -public workflow::impl::acs_object {} { 
    Returns the static string 'acs_object'. This can be used by implementations that are valid for any object type.
} { 
    return "acs_object"
}


#####
#
# Role - Default Assignee - Creation User
#
#####

ad_proc -public workflow::impl::role_default_assignees::creation_user::pretty_name {} {
    return "Assign to the user who created this object"
}

ad_proc -public workflow::impl::role_default_assignees::creation_user::get_assignees {
    case_id
    object_id
    role_id
} {
    Return the creation_user of the object
} {
    return [db_string select_creation_user {}]
}



#####
#
# Role - Default Assignee - Static Assignees
#
#####

ad_proc -public workflow::impl::role_default_assignees::static_assignees::pretty_name {} {
    return "Use static assignment"
}

ad_proc -public workflow::impl::role_default_assignees::static_assignees::get_assignees {
    case_id
    object_id
    role_id
} {
    Return the static assignees for this role
} {
    return [db_list select_static_assignees {}]
}

#####
#
# Pick list - Default assignees
#
#####

ad_proc -public workflow::impl::role_assignee_pick_list::current_assignees::pretty_name {} {
    return "Current asignees"
}

ad_proc -public workflow::impl::role_assignee_pick_list::current_assignees::get_pick_list {
    case_id
    object_id
    role_id
} {
    Return the list of current assignees for this case and role
} {
    return [db_list select_current_assignees {}]
}




#####
#
# Search Subquery - registered users
#
#####

ad_proc -public workflow::impl::role_assignee_subquery::registered_users::pretty_name {} {
    return "All registered users"
}

ad_proc -public workflow::impl::role_assignee_subquery::registered_users::get_subquery {
    case_id
    object_id
    role_id
} {
    Return a subquery for all registered users.
} {
    return [db_map cc_users]
}



#####
#
# Notifications
#
#####

ad_proc -public workflow::impl::notification::get_url {
    object_id
} {
    # Todo: Implement this proc
}

ad_proc -public workflow::impl::notification::process_reply {
    reply_id
} {
    # Todo: Implement this proc
}    

