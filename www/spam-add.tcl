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
    @creation-date 2000-12-12
    @cvs-id $Id$

} {
    { sql_query ""}
    { object_id 0}
} -properties {
    spam_id:onevalue
    num_recipients:onevalue
    export_vars:onevalue
    date_widget:onevalue
    time_widget:onevalue
    context:onevalue
} 

if {$sql_query == ""} { 
    ad_return_complaint 1 "No user query supplied.  You can't invoke this \
	    page directly."
    return 
}

ad_require_permission $object_id write

# generate sequence value; double-click protection
set spam_id [db_nextval acs_object_id_seq]

set object_name [db_string object_name_for_one_object_id "select acs_object.name(:object_id) from dual" -default ""]
set object_type [db_string object_type "select object_type from acs_objects where object_id = :object_id"]
set object_rel_url [db_string object_url "select url from im_biz_object_urls where url_type = 'view' and object_type = :object_type"]
append object_rel_url $object_id


set num_recipients [db_string get_num_recipients "
    select count(*) from ($sql_query)
"]

set spam_show_users_url "spam-show-users?[export_url_vars object_id sql_query]"

set export_vars [export_form_vars num_recipients spam_id]

set date_widget [ad_dateentrywidget send_date]
set time_widget [spam_timeentrywidget send_time]

set context [list "add message"]

ad_return_template






    
    
    
    
    