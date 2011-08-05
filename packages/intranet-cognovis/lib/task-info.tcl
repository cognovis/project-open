ad_page_contract {
    The display for the task base data 
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-07

} 
set user_id [ad_conn user_id] 

# get the current users permissions for this project
im_project_permissions $user_id $task_id view read write admin

# ---------------------------------------------------------------------
# Get Everything about the task
# ---------------------------------------------------------------------

set extra_selects [list "0 as zero"]
  


db_foreach column_list_sql {
      select	w.deref_plpgsql_function,
                aa.attribute_name,
		aa.table_name
      from    	im_dynfield_widgets w,
      		im_dynfield_attributes a,
      		acs_attributes aa
      where   	a.widget_name = w.widget_name and
      		a.acs_attribute_id = aa.attribute_id and
      		aa.object_type = 'im_timesheet_task'
      

}  {
	lappend extra_selects "${deref_plpgsql_function}(${table_name}.$attribute_name) as ${attribute_name}_deref"
}
    
set extra_select [join $extra_selects ",\n\t"]

if {[exists_and_not_null extra_select]} {
    set extra_where  "AND im_timesheet_tasks.task_id = im_projects.project_id"
}

if { ![db_0or1row project_info_query "
	select
		im_projects.*,
		im_companies.*,
                im_timesheet_tasks.*,
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
		im_companies,
                im_timesheet_tasks
        WHERE   im_projects.project_id=:task_id
		and im_projects.company_id = im_companies.company_id
        $extra_where      

"] } {
	ad_return_complaint 1 "[_ intranet-core.lt_Cant_find_the_project]"
	return
}

set task_type [im_category_from_id $task_type_id]
set task_status [im_category_from_id $task_status_id]

# Get the parent project's name
if {"" == $parent_id} { set parent_id 0 }
set parent_name [util_memoize [list db_string parent_name "select project_name from im_projects where project_id = $parent_id" -default ""]]

if {$task_type_id eq ""} {
    set task_type_id 9500
}

# ---------------------------------------------------------------------
# Add DynField Columns to the display

set old_section ""
db_multirow -extend {attrib_var value} task_info dynfield_attribs_sql {
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
      			where page_url = ''
      		) la ON (a.attribute_id = la.attribute_id)
      where
    a.widget_name = w.widget_name and
    a.acs_attribute_id = aa.attribute_id and
    aa.object_type = 'im_timesheet_task' and
    a.attribute_id = m.attribute_id and
    object_type_id = :task_type_id and
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
	
}

set current_user_id [ad_conn user_id]
im_project_permissions $current_user_id $task_id view read write admin

if {$write eq 0} {
    im_project_permissions $current_user_id $parent_id view_project read_project write admin_project
}

if {[exists_and_not_null no_write_p]} {
    set write 0
}
