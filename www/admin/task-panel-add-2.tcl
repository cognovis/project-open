ad_page_contract {
    Add the panel.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date December 12, 2000
    @cvs-id $Id$
} {
    workflow_key:notnull
    transition_key:notnull
    {context_key "default"}
    header
    template_url
    only_display_when_started_p:boolean
    overrides_action_p:boolean
    {return_url "task-panels?[export_vars -url { workflow_key transition_key context_key }]"}
    cancel:optional
} -validate {
    header_and_template_url -requires { header template_url } {
	if { ![info exists cancel] || [empty_string_p $cancel] } {
	    if { [empty_string_p $header] || [empty_string_p $template_url] } {
		ad_complain "You must specify both a header and a template URL"
	    }
	}
    }
} 


if { ![info exists cancel] || [empty_string_p $cancel] } {

    db_dml panel_add {
	insert into wf_context_task_panels
	    (workflow_key, transition_key, context_key, sort_order, header, template_url)
	select :workflow_key, :transition_key, :context_key, nvl(max(sort_order)+1,1), :header, :template_url
	from   wf_context_task_panels
	where  workflow_key = :workflow_key
	and    transition_key = :transition_key
	and    context_key = :context_key
    }   
}

ad_returnredirect $return_url
