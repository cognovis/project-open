ad_page_contract {
    The display for the project base data 
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @author malte sussdorff (malte.sussdorff@cognovis.de)
    @date 2010-10-07

} 



# Instantiate the project object
set project [::im::dynfield::Class get_instance_from_db -id $project_id]

# Get the list of dynfields for this project based on the project_type_id
set dynfield_ids [db_list dynfields "select m.attribute_id from im_dynfield_type_attribute_map m, im_dynfield_layout d  where object_type_id = [$project project_type_id] and m.attribute_id = d.attribute_id order by pos_y"]

# Initialize project information 
template::multirow create project_info heading field value
set old_section ""

foreach dynfield_id $dynfield_ids {
    
    # Initialize the Attribute                                                 
    set element [im::dynfield::Element get_instance_from_db -id $dynfield_id]
    
    set field [$element pretty_name]  
    set value [$project value $element]
    
    if {[$element multiple_p] && $value ne ""} {
	set value "<ul><li>[join $value "</li><li>"]</li></ul>"
    }

    set heading ""
    
    if {$old_section != [$element section_heading]} {
	set heading [$element section_heading]
       	set old_section [$element section_heading]
	
    }   

    template::multirow append project_info $heading $field $value
    
}

set current_user_id [ad_conn user_id]
im_project_permissions $current_user_id $project_id view read write admin
set edit_project_base_data_p [im_permission $current_user_id edit_project_basedata]