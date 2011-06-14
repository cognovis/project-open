ad_page_contract {
    The display for the task base data 
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-07

} 

# Instantiate the task object
set task [::im::dynfield::Class get_instance_from_db -id $task_id]

# Get the list of dynfields for this task based on the task_type_id
set dynfield_ids [db_list dynfields "select m.attribute_id from acs_attributes aa, im_dynfield_attributes a, im_dynfield_type_attribute_map m, im_dynfield_layout d  where object_type_id = 100 and m.attribute_id = d.attribute_id and aa.attribute_id = a.acs_attribute_id and a.attribute_id = m.attribute_id and aa.object_type = 'im_timesheet_task' order by pos_y"]

# Initialize task information 
template::multirow create task_info heading field value
set old_section ""

foreach dynfield_id $dynfield_ids {
    
    # Initialize the Attribute                                                 
    set element [im::dynfield::Element get_instance_from_db -id $dynfield_id]
    set pretty_name [$element pretty_name]
    set pretty_name_key "intranet-core.[lang::util::suggest_key $pretty_name]"
    set field [lang::message::lookup "" $pretty_name_key $pretty_name]
    #set field [$element pretty_name]  
    set value [$task value $element]
    
    if {[$element multiple_p] && $value ne ""} {
	set value "<ul><li>[join $value "</li><li>"]</li></ul>"
    }

    set heading ""
    
    if {$old_section != [$element section_heading]} {
	set heading [$element section_heading]
       	set old_section [$element section_heading]
	
    }   

    template::multirow append task_info $heading $field $value
    
}

set current_user_id [ad_conn user_id]
im_project_permissions $current_user_id $task_id view read write admin


