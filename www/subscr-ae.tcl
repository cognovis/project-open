ad_page_contract {

    Present an admin page for adding or editing subscriptions.

    We should either get a subscr_id (editing) or
    impl_id + summary_context_id (adding).

    Set the meta urlarg to 0 to prevent generating a report from which
    we pull out channel title and link.

    It would be very tempting to accept impl_name as an argument
    instead of impl_id.  However, the "apply" call in acs_sc_call
    raises the ugly possibility of code-smuggling through the url,
    so we will force the use of the easily validated impl_id
    instead.

} {
    subscr_id:optional,naturalnum
    impl_id:optional,naturalnum
    summary_context_id:optional,naturalnum
    return_url:optional
    {meta:optional 1}
} -validate {
    subscr_or_context {
	if { !(([info exists subscr_id]) || ([info exists impl_id] && [info exists summary_context_id])) } {
	    ad_complain "We were unable to
	    process your request.  Please contact this site's
	    technical team for assistance."
	}
    }
}

if { [info exists impl_id] && [info exists summary_context_id] } {
    db_0or1row subscr_id_from_impl_and_context {}
}

if [info exists subscr_id] {
    set action edit
    set pretty_action Edit
    ad_require_permission $subscr_id admin
    db_1row subscr_info {}
} else {
    set action add
    set pretty_action Add
    ad_require_permission $summary_context_id admin
    set subscr_id [db_nextval acs_object_id_seq]
    set timeout 3600
}

# Validate the impl_id and get its name
if ![db_0or1row get_impl_name_and_count {}] {
    ad_return_error "No implementation found for this id." "We were unable to
process your request.  Please contact this site's technical team for
assistance."
}

if { ![info exists channel_title] || [string equal $channel_title ""] || [string equal $channel_link ""] } {
    if !$meta {
	if [string equal $channel_title ""] {
	    set channel_title "Summary Context $summary_context_id"
	}
    } else {
	# Pull out channel data by generating a summary.
	# This is a convenient way to use a contracted operation
	# but is not terribly efficient since we only need the channel title
	# and link, and not the whole summary.
	foreach {name val} [acs_sc_call RssGenerationSubscriber datasource \
		$summary_context_id $impl_name] {
	    if { [lsearch {channel_title channel_link} $name] >= 0 } {
		set $name $val
	    }
	} 
    }
}

set formvars [export_form_vars subscr_id           \
			       impl_id             \
			       summary_context_id  \
			       return_url          \
			       meta]

set context [list Add/Edit]

