ad_page_contract {
    form to add a new spam message to the spam_messages table

    arguments:
    sql_query is the query that is used to generate the list of users.
    it must return a party_id column.

    object_id is the object_id that is creating the spam, or that is 
    associated with the spam.  If the current user has admin permission
    on that object_id, any spam he sends does not need approval.  Otherwise,
    it will be held until it is approved by an administrator. 
    
    @author bschneid@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    { selector_id 0 }
    { selector_short_name "" }
    { object_id 0}
} -properties {
    spam_id:onevalue
    num_recipients:onevalue
    export_vars:onevalue
    date_widget:onevalue
    time_widget:onevalue
    context:onevalue
} 

set context [list "add message"]


# Get sql_query based on a selector_short_name
#
if {"" != $selector_short_name} {
    set selector_id [db_string get_selector_id "
	select	selector_id
	from	im_sql_selectors
	where	short_name = :selector_short_name
    " -default 0]
}

if {0 == $selector_id} {
    set error "Unknown selector short name '$selector_short_name'"
    ad_return_template spam-add-error
    return
}


set sql_query [db_string sql_query "
	select	selector_sql
	from	im_sql_selectors
	where	selector_id = :selector_id
" -default ""]


# --------------------------------------------------

ad_require_permission $object_id write

# generate sequence value; double-click protection
set spam_id [db_nextval acs_object_id_seq]

set object_name [db_string object_name_for_one_object_id "select acs_object.name(:object_id) from dual" -default ""]
set object_type [db_string object_type "select object_type from acs_objects where object_id = :object_id"]
set object_rel_url [db_string object_url "select url from im_biz_object_urls where url_type = 'view' and object_type = :object_type"]
append object_rel_url $object_id


# --------------------------------------------------

set spam_show_users_url "spam-show-users?[export_url_vars object_id selector_id]"

set export_vars [export_form_vars spam_id]

set date_widget [ad_dateentrywidget send_date]
set time_widget [spam_timeentrywidget send_time]

# db_multirow spam_list spam_get_party_list  {}


# --------------------------------------------------
# Get number and fields of sql query results
# --------------------------------------------------

db_with_handle -dbn "" db {
    set selection [db_exec select $db full_statement_name $sql_query]

    set query_fields [list]
    set query_field_html ""

    # get only a single result
    if { [db_getrow $db $selection] } {
	for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
	    lappend query_fields [ns_set key $selection $i]
	    if {"" != $query_field_html} { append query_field_html ", " }
	    append query_field_html "[ns_set key $selection $i]"
	}
    }
}

set query_field_html "user_first_names, user_last_name, user_email, user_name, $query_field_html"