ad_page_contract {
    The display for the project base data 
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @author malte sussdorff (malte.sussdorff@cognovis.de)
    @date 2010-10-07

} 


set user_id [ad_conn user_id] 

# get the current users permissions for this project
im_project_permissions $user_id $project_id view read write admin
set edit_project_base_data_p [im_permission $user_id edit_project_basedata]

# ---------------------------------------------------------------------
# Get Everything about the task
# ---------------------------------------------------------------------

set table_names [list im_projects im_companies]
set extra_where ""
set extra_selects [list]

db_foreach column_list_sql {
      select	w.deref_plpgsql_function,
                aa.attribute_name,
		aa.table_name
      from    	im_dynfield_widgets w,
      		im_dynfield_attributes a,
      		acs_attributes aa
      where   	a.widget_name = w.widget_name and
      		a.acs_attribute_id = aa.attribute_id and
      		aa.object_type = 'im_project'
      

}  {
    lappend extra_selects "${deref_plpgsql_function}(${table_name}.$attribute_name) as ${attribute_name}_deref"
    if {[lsearch $table_names $table_name]<0} {
	ad_return_error "Currently not supported" "We are sorry, but additional table names are not supported at this point in time: $table_name"
#	lappend table_names $table_name
#	append extra_where "and ${table_name}
    }
}


set extra_select [join $extra_selects ",\n\t"]

if { ![db_0or1row project_info_query "
	select
		im_projects.*,
		im_companies.*,
		to_char(im_projects.end_date, 'HH24:MI') as end_date_time,
		to_char(im_projects.start_date, 'YYYY-MM-DD') as start_date_formatted,
		to_char(im_projects.end_date, 'YYYY-MM-DD') as end_date_formatted,
		to_char(im_projects.percent_completed, '999990.9%') as percent_completed_formatted,
		im_companies.primary_contact_id as company_contact_id,
		im_name_from_user_id(im_companies.primary_contact_id) as company_contact,
		im_email_from_user_id(im_companies.primary_contact_id) as company_contact_email,
		im_name_from_user_id(im_projects.project_lead_id) as project_lead,
		im_name_from_user_id(im_projects.supervisor_id) as supervisor,
		im_name_from_user_id(im_companies.manager_id) as manager,
		$extra_select
	from
		im_projects, 
		im_companies
        WHERE   im_projects.project_id=:project_id
		and im_projects.company_id = im_companies.company_id"] } {
	ad_return_complaint 1 "[_ intranet-core.lt_Cant_find_the_project]"
	return
}


set project_type [im_category_from_id $project_type_id]
set project_status [im_category_from_id $project_status_id]

# Get the parent project's name
if {"" == $parent_id} { set parent_id 0 }
set parent_name [util_memoize [list db_string parent_name "select project_name from im_projects where project_id = $parent_id" -default ""]]


# ---------------------------------------------------------------------
# Add DynField Columns to the display

set old_section ""
db_multirow -extend {attrib_var value} project_info dynfield_attribs_sql {
      select
      		aa.pretty_name,
      		aa.attribute_name,
                m.section_heading,
                w.widget
      from
      		im_dynfield_widgets w,
      		acs_attributes aa,
                im_dynfield_type_attribute_map m,
      		im_dynfield_attributes a
      		LEFT OUTER JOIN (
      			select *
      			from im_dynfield_layout
      			where page_url = 'default'
      		) la ON (a.attribute_id = la.attribute_id)
      where
    a.widget_name = w.widget_name and
    a.acs_attribute_id = aa.attribute_id and
    aa.object_type = 'im_project' and
    a.attribute_id = m.attribute_id and
    object_type_id = :project_type_id and
    display_mode in ('edit','display')
    order by la.pos_y
    
} {

    set heading ""
    
    if {$old_section != $section_heading} {
        set heading $section_heading
        set old_section $section_heading
        
    }   
   
    # Set the field name
    set pretty_name_key "intranet-core.[lang::util::suggest_key $pretty_name]"
    set pretty_name [lang::message::lookup "" $pretty_name_key $pretty_name]

    # Set the value
    set var ${attribute_name}_deref
    set value [set $var]
    if {$widget eq "richtext"} {
	set value [template::util::richtext::get_property contents $value]
    }

    # Special setting for projects (parent_id)
    if {$attribute_name eq "parent_id"} {
	set project_url [export_vars -base "[im_url]/projects/view" -url {{project_id $parent_id}}]
	set value "<a href='$project_url'>$value</a>"
    }
	
}


# -----------------------------------
# Notification Subscription Button
# -----------------------------------

# Provide the subscribe / unsubscribe option
set notification_type_id [notification::type::get_type_id -short_name "project_notif"]
set notification_request_id [notification::request::get_request_id \
				 -type_id $notification_type_id \
				 -object_id $project_id \
				 -user_id $user_id]
set notification_return_url [im_url_with_query]

if { $notification_request_id ne "" } {
    set notification_url [notification::display::unsubscribe_url -request_id $notification_request_id -url $notification_return_url]
    set notification_message [_ notifications.lt_Ubsubscribe_Notification_ [list pretty_name "$project_name"]]
    set notification_button [_ notifications.Unsubscribe]
} else {
    set notification_delivery_method_id  [notification::get_delivery_method_id -name "email"]
    set notification_interval_id [notification::get_interval_id -name "instant"]
    set notification_url [export_vars -base "/notifications/request-new?" {
	{object_id $project_id} 
	{type_id $notification_type_id}
	{delivery_method_id $notification_delivery_method_id}
	{interval_id $notification_interval_id}
	{"form\:id" "subscribe"}
	{formbutton\:ok "OK"}
	{return_url $notification_return_url}
    }]
    set notification_message [_ notifications.lt_Request_Notification_ [list pretty_name "$project_name"]]
    set notification_button [_ notifications.Request_Notification]
}
