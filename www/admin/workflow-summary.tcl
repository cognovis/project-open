# /packages/acs-workflow/www/admin/workflow-summary.tcl

ad_page_contract {
    Displays basic aggregate statistics on a workflow

    @param workflow_key the identifying key for the workflow

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date 23 Aug 2000
    @cvs-id $Id$
} {
    workflow_key:notnull,trim
} -validate {
    workflow_exists -requires {workflow_key} {
	if ![db_string workflow_exists "
	select 1 from wf_workflows 
	where workflow_key = :workflow_key"] {
	    ad_complain "You seem to have specified a nonexistent workflow."
	}
    }
} -properties {
    workflow_name
    workflow_key
    num_cases_total
    num_cases:onerow
    simple_p
    context
    places:multirow
    transitions:multirow
    simple_steps:multirow
}

# -----------------------------------------------------------------------------

db_1row workflow_name {
    select pretty_name as workflow_name
    from   acs_object_types
    where  object_type = :workflow_key
}

set workflow_name [ad_quotehtml $workflow_name]

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] "Workflow Summary"]

set workflow_info [wf_get_workflow_net $workflow_key]
array set workflow $workflow_info

wf_decorate_workflow workflow


#####
#
# Number of cases
#
#####
    
set num_cases_total [db_string n_total {
    select count(*) 
    from   wf_cases
    where  workflow_key = :workflow_key
}]

array set num_cases_in_state {
    created 0
    active 0
    suspended 0
    canceled 0
    finished 0
}

db_foreach num_cases {
    select state, count(case_id) as num
    from   wf_cases
    where  workflow_key = :workflow_key
    group by state
} {
    set num_cases_in_state($state) $num
}

foreach name [array names num_cases_in_state] {
    set cases_url_for_state($name) "cases?[export_vars -url {workflow_key {state $name}}]"
}




#####
#
# Count tokens
#
#####

# we do a count(t.workflow_key) instead of count(*) to get the right
# behavior when there are zero tokens (otherwise the outer join will
# give you a result of 1).


set pixels_per_case 5

    

db_multirow places places {
    select p.place_key, 
           p.place_name,
          (select count(*)
           from   wf_tokens t, wf_cases c
           where  t.workflow_key = p.workflow_key
           and    t.place_key    = p.place_key
           and    t.state in ('free')
           and    c.case_id = t.case_id
           and    c.state = 'active') as num_cases,
           0 as num_pixels,
           '' as cases_url
    from   wf_places p
    where  p.workflow_key = :workflow_key
    order by p.sort_order
} {
    if { $num_cases > 0 } { 
	set workflow(place,$place_key,place_name) "$place_name\\n[string repeat "*" $num_cases]"
    }
    set num_pixels [expr {$num_cases * $pixels_per_case}]
    set cases_url "cases?[export_vars -url {workflow_key place_key {state active}}]"
}

db_multirow transitions transitions {
    select tr.transition_key, 
           tr.transition_name,
	   (select count(*) 
            from   wf_tasks ta, wf_cases c
	    where  ta.workflow_key = tr.workflow_key
	    and    ta.transition_key = tr.transition_key
	    and    ta.state in ('started')
            and    c.case_id = ta.case_id
            and    c.state = 'active') as num_cases,
           0 as num_pixels,
           '' as cases_url
    from   wf_transitions tr
    where  tr.workflow_key = :workflow_key
    order by tr.sort_order
} {
    if { $num_cases > 0 } { 
	set workflow(transition,$transition_key,transition_name) "$transition_name\\n[string repeat "*" $num_cases]"
    }
    set num_pixels [expr {$num_cases * $pixels_per_case}]
    set cases_url "cases?[export_vars -url {workflow_key transition_key {state active}}]"
}

# fraber 20100602: wf_simple_workflow_p returns an error...
# set simple_p [wf_simple_workflow_p $workflow_key]
set simple_p 0

db_release_unused_handles

template::multirow create simple_steps type key name num_cases

if { $simple_p } {
    for { set i 1 } { $i <= ${places:rowcount} } { incr i } {
	upvar 0 places:$i places

	template::multirow append simple_steps "place" $places(place_key) $places(place_name) $places(num_cases)

	if { $i <= [expr ${places:rowcount} - 1] } {
	    upvar 0 transitions:$i transitions

	    template::multirow append simple_steps "transition" $transitions(transition_key) \
		    $transitions(transition_name) $transitions(num_cases)

	}
    }
}



#####
#
# Create the workflow gif
#
#####

if { [wf_graphviz_installed_p] } {

    set dot_text [wf_generate_dot_representation workflow]
    
    set tmpfile [wf_graphviz_dot_exec -to_file -output gif $dot_text]
    
    set width_and_height ""
    if { ![catch { set image_size [ns_gifsize $tmpfile] } error] } {
	if { ![empty_string_p $image_size] } {
	    set width_and_height "width=[lindex $image_size 0] height=[lindex $image_size 1]"
	}
    }
    
    ad_set_client_property wf wf_net_tmpfile $tmpfile
    
    set workflow_img_tag "<img src=\"[im_workflow_url]/workflow-gif?[export_url_vars tmpfile]\" border=0 $width_and_height alt=\"Graphical representation of the process network\">"
    
} else {
    set workflow_img_tag ""
}

ad_return_template


