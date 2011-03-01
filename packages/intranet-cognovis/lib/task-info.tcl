ad_page_contract {
    The display for the project base data 
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-07

} 

    # Instantiate the project object
    set task [::im::dynfield::Class get_instance_from_db -id $task_id]
    
    set list_ids [$task list_ids]
    set html "<table>"
    
    set old_section ""
    
    foreach dynfield_id [::im::dynfield::Attribute dynfield_attributes -list_ids $list_ids -privilege "read"] {
	
        # Initialize the Attribute
                                                                                                                           
        set element [im::dynfield::Element get_instance_from_db -id [lindex $dynfield_id 0] -list_id [lindex $dynfield_id 1]]
        set value [$task value $element]

	#if {[string equal [lindex $value 1] "text/html"]} {
	   #treat richtext field
	#    ns_log Notice "TREAT RICHTEXT text/html"
	#    set value [lindex $value 0]
	#}

        if {[$element multiple_p] && $value ne ""} {
            set value "<ul><li>[join $value "</li><li>"]</li></ul>"
        }
	
        if {$old_section != [$element section_heading]} {
            append html "
            <tr>
              <td colspan=\"2\" align=\"left\"><h3 class=\"contact-title\">[$element section_heading]</h3></td>
            </tr>"
            set old_section [$element section_heading]
        }
	
	append html "
             <tr>
               <td align=\"right\" valign=\"top\" class=\"attribute\"> [$element pretty_name]:</td>
               <td align=\"left\" valign=\"top\" class=\"value\">$value</td>
            </tr>"	
    }

    append html "</table><form action='/intranet-cognovis/tasks/task-ae'><input type='hidden' name=task_id value='$task_id'><input type='submit' value='[_ acs-kernel.common_Edit]'></form>"
