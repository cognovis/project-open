ad_page_contract {
    Displays Ticket Info Cognovis Component

    @author Iuri Sampaio (iuri.sampaio@iurix.com)
    @creation-date 2011-06-06
}





# Instantiate the task object
set ticket [::im::dynfield::Class get_instance_from_db -id $ticket_id]

# Get the list of dynfields for this task based on the task_type_id
set dynfield_ids [db_list dynfields {     
    SELECT DISTINCT m.attribute_id FROM acs_attributes aa, im_dynfield_attributes a, im_dynfield_type_attribute_map m, im_dynfield_layout d 
    WHERE m.attribute_id = d.attribute_id and aa.attribute_id = a.acs_attribute_id and a.attribute_id = m.attribute_id and aa.object_type = 'im_ticket' and object_type_id in (select DISTINCT m.object_type_id from acs_attributes aa, im_dynfield_attributes a, im_dynfield_type_attribute_map m, im_dynfield_layout d  where m.attribute_id = d.attribute_id and aa.attribute_id = a.acs_attribute_id and a.attribute_id = m.attribute_id and aa.object_type = 'im_ticket')                           
   }]

# Initialize ticket information 
template::multirow create ticket_info heading field value
set old_section ""

foreach dynfield_id $dynfield_ids {
    
    # Initialize the Attribute                                                 
    set element [im::dynfield::Element get_instance_from_db -id $dynfield_id]
    
    set field [$element pretty_name]  
    set value [$ticket value $element]
    
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
im_project_permissions $current_user_id $ticket_id view read write admin


