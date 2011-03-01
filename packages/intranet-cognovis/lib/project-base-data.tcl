ad_page_contract {
    The display for the project base data 
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-07

} 



# Instantiate the project object
set project [::im::dynfield::Class get_instance_from_db -id $project_id]

set list_ids [$project list_ids]

set old_section ""


template::multirow create company_info heading field value

foreach dynfield_id [::im::dynfield::Attribute dynfield_attributes -list_ids $list_ids -privilege "read"] {
    
    # Initialize the Attribute                                                 
    
    set element [im::dynfield::Element get_instance_from_db -id [lindex $dynfield_id 0] -list_id [lindex $dynfield_id 1]]
    
    set field [$element pretty_name]  
    set value [$project value $element]
    
    if {[string equal [lindex $value 1] "text/html"]} {
	set value [lindex $value 0]
    }
    
    if {[$element multiple_p] && $value ne ""} {
	set value "<ul><li>[join $value "</li><li>"]</li></ul>"
    }

    set heading ""
    
    if {$old_section != [$element section_heading]} {
	set heading [$element section_heading]
       	set old_section [$element section_heading]
	
    }   

    template::multirow append company_info $heading $field $value
    
}

set current_user_id [ad_conn user_id]
im_project_permissions $current_user_id $project_id view read write admin
set edit_project_base_data_p [im_permission $current_user_id edit_project_basedata]