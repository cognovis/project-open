# /www/intranet/projects/member-update.tcl

ad_page_contract {
    Allows to delete project members and to update
    their time/cost estimates for this project.
} {
    group_id:integer
    days:array,optional
    { return_url "" }
    { submit "" }
    { delete_user:multiple,integer "" }
}

set user_id [ad_maybe_redirect_for_registration]

ns_log Notice "group_id=$group_id"
ns_log Notice "submit=$submit"
ns_log Notice "delete_user(multiple)=$delete_user"

# "Del" button pressed: delete the marked users
#
if {[string equal $submit "Del"]} {
    foreach user $delete_user {
	ns_log Notice "delete user: $user"

	group::remove_member \
	    -group_id $group_id \
	    -user_id $user
    }
}


# "Save" button pressed: Save the new estimation values
#
if {[string equal $submit "Save"]} {
    set user_list [array names days]
    foreach user $user_list {
	regsub {\,} $days($user) {.} days($user)
	ns_log Notice "days(user)=$days($user)"
	set sql "
		update USER_GROUP_MEMBER_FIELD_MAP
		set field_value='$days($user)'
		where group_id=:group_id
		and user_id='$user'
		and field_name='estimation_days'"
        db_dml update_days $sql
    }
}

#doc_return  200 text/html ""
ad_returnredirect $return_url












