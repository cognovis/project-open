ad_page_contract {
    View active cases.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 September 2000
    @cvs-id $Id$
} {
    workflow_key:notnull,trim
    {orderby "started_date_pretty"}
} -validate {
    workflow_exists -requires {workflow_key} {
	if ![db_string workflow_exists "
	select 1 from wf_workflows 
	where workflow_key = :workflow_key"] {
	    ad_complain "You seem to have specified a nonexistent workflow."
	}
    }
} -properties {
    context
    workflow_name
    cases:multirow
    dimensional_html
    table_html
}



db_1row workflow_name {
    select pretty_name as workflow_name
    from   acs_object_types
    where  object_type = :workflow_key
}

set workflow_name [ad_quotehtml $workflow_name]

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow_name"] "Cases"]


#
# Use ad_table here
#



set dimensional_list {
    {
        state "State" all {
	    { created "Created" { where "c.state = 'created'" } }
	    { active "Active" { where "c.state = 'active'" } }
	    { suspended "Suspended" { where "c.state = 'suspended'" } }
	    { canceled "Canceled" { where "c.state = 'canceled'" } }
	    { finished "Finished" { where "c.state = 'finished'" } }
	    { all "-- All --" {} }
	}
    }
}

set transitions_dim [list]
db_foreach transitions {
    select transition_key, transition_name 
    from   wf_transitions
    where  workflow_key = :workflow_key
    order by transition_name
} {
    lappend transitions_dim [list $transition_key $transition_name [list where "exists (select 1 from wf_tasks ta
	    where ta.workflow_key = '[db_quote $workflow_key]'
	    and ta.transition_key = '[db_quote $transition_key]'
	    and ta.state = 'started'
            and ta.case_id = c.case_id)"]]
}
lappend transitions_dim [list all "-- All --" {}]

set places_dim [list]
db_foreach places {
    select place_key, place_name
    from   wf_places
    where  workflow_key = :workflow_key
    order by place_name
} {
    lappend places_dim [list $place_key $place_name [list where "exists (select 1 from wf_tokens tok
           where  tok.workflow_key = '[db_quote $workflow_key]'
           and    tok.place_key    = '[db_quote $place_key]'
           and    tok.state = 'free'
           and    tok.case_id = c.case_id)"]]
}
lappend places_dim [list all "-- All --" {}]


lappend dimensional_list [list transition_key "Task" all $transitions_dim]
lappend dimensional_list [list place_key "Place" all $places_dim]


set missing_text "<em>No cases match criteria.</em>"

set dimensional_html [ad_dimensional $dimensional_list "" "" "select"]
# The above does obviously not render very nicely.
# Some day we should really implement the option on ad_dimensional to render as <select> boxes.

set table_def {
    { object_name "Object Name" "" "<td><a href=\"../case?[export_vars -url {case_id}]\">$object_name</a></td>" }
    { object_type_pretty "Object Type" "" "" }
    { state "State" "" "<td>[string totitle $state]</td>" }
    { started_date_pretty "Started" "started_date" "" }
    { age "Age" "" "<td align=\"right\">$age</td>" }
    { action "" "" "<td>(<a href=\"case-debug?[export_vars -url {case_id}]\">debug</a>)</td>" }
}


set table_html [ad_table -Torderby $orderby -Tmissing_text $missing_text "cases_table" "" $table_def]

db_release_unused_handles


ad_return_template


