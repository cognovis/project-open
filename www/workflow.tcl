ad_page_contract {
    Admin big picture view of a workflow, including places, transitions and arcs

    @author Ryan Bender (jrbender@mit.edu)
    @creation-date 23 August 2000
    @cvs-id $Id$
} {
    workflow_key:notnull
}

array set wf_info [wf_workflow_info $workflow_key]

set workflow_name $wf_info(pretty_name)

doc_body_append "
[ad_header $workflow_name]
<h2>$workflow_name</h2>

[ad_context_bar [list "./" "Work List"] [list admin "Workflow Admin"] $workflow_name]

<hr>

<blockquote>
"

doc_body_append "<form>

<table cellspacing=0 cellpadding=4 border=0>

<tr bgcolor=#f4f4f4>
<th>Order</th>
<th>Task</th>
<th>Task Output</th>
<th>Loop back to task...</th>
<th>... if</th>
</tr>
"

# note: 'transition' in db means 'task' in UI

set task_num 1 
set bgcolor "#e6e6e6"

foreach transition $wf_info(transitions) {
    array set trans $transition

    set transition_key $trans(transition_key)
    
    # transition-edit.tcl will be a form to enter 2 textareas, 
    # 'inputs' and 'logic or aids', which show up on task.tcl
    doc_body_append "
    <tr bgcolor=$bgcolor>
    <td align=center><strong>$task_num.</strong></td>
    <td><a href=\"transition-edit?[export_url_vars transition_key]\">$trans(transition_name)</a></td>
    "

    # the attributes which the loop can depend on (the '..if' part)
    set selectbox_if_items [list]

    # attribute-edit will be form for user to enter the type, label, presentation
    # of an attribute on task.tcl
    set attribute_display ""
    foreach attribute $trans(attributes) {
	array set attr $attribute

	set attribute_name $attr(attribute_name)
	append attribute_display "<a href=\"attribute-edit?[export_url_vars attribute_name]\">$attr(attribute_name)</a><br>"
	lappend selectbox_if_items $attr(attribute_name)
    }

    doc_body_append "<td>$attribute_display
    <input type=text name=$trans(transition_key).new_attribute_name value=\"\"></td>"

    # display tasks you already have loopbacks to ... UNFINSHED
    #      db_foreach loopbacks {
	#  	select 
	#  	from wf_arcs 
	#  	where transition_key = :transition_key
	#  	and direction = 'out'
	#  	and workflow_key = :workflow_key
	#      }


    # the tasks you can loopback to from this one
    set selectbox_loopback_items [list "--No loop--"]
    set selectbox_loopback_values [list "no_loop"]

    foreach possible_transition $wf_info(transitions) {
	array set poss_trans $possible_transition
	if { $poss_trans(sort_order) < $trans(sort_order) } {
	    lappend selectbox_loopback_items $poss_trans(transition_name)
	    lappend selectbox_loopback_values $poss_trans(transition_key)
	}	
    }
    
    if { [llength $selectbox_loopback_items] < 2 } {
	set selectbox_loopback_options "--No loop--"
    } else {
	set selectbox_loopback_options "<select name=loop_task>
	[ad_generic_optionlist $selectbox_loopback_items $selectbox_loopback_values]
	</select>"
    }

    doc_body_append "<td align=center>$selectbox_loopback_options</td>"

    if { [llength $selectbox_loopback_items] < 2 } {
	set selectbox_if_options "--No condition--"
    } else {
	if { [llength $selectbox_if_items] == 1 } {
	    set selectbox_if_options "<strong>$selectbox_if_items</strong>"
	    set loop_attribute $selectbox_if_items
	    append selectbox_if_options [export_form_vars loop_attribute]
	} elseif { [llength $selectbox_if_items] > 1 } {
	    set selectbox_if_options "<select name=loop_attribute>
	    [ad_generic_optionlist $selectbox_if_items $selectbox_if_items]
	    </select>"
	}
	
	# below is a hack to have some values to set the attrs to
	# really we should select from acs_attributes to get the possible values
	append selectbox_if_options " is <select name=loop_value>[ad_generic_optionlist [list true false] [list t f]]</select>"
    }

    doc_body_append "
    <td align=center>$selectbox_if_options</td>"
        
    incr task_num
    
    if { [expr $task_num % 2] == 0 } {
	set bgcolor "#f4f4f4"
    } else {
	set bgcolor "#e6e6e6"
    }
}

doc_body_append "
<tr bgcolor=$bgcolor>
<td align=center><strong>$task_num.</strong></td>
<td><input type=text name=new_task_name value=\"\"></td>

</table>

</blockquote>
[ad_footer]
"

