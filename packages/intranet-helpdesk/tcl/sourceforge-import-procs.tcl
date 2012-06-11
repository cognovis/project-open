# /packages/intranet-helpdesk/tcl/soureforge-import.tcl
#
# Copyright (c) 2012 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}




# ----------------------------------------------------------------------
# Get Exchange Rate from Update Server
# ----------------------------------------------------------------------

ad_proc -public im_helpdesk_sourceforge_tracker_import_sweeper { } {
    Loads the RSS contents of a SF tracker and inserts the ticktes
    into ]po[.
} {
    ns_log Notice "im_helpdesk_sourceforge_tracker_import_sweeper: starting"

    set system_owner_id [db_string system_owner "select min(user_id) from users where user_id > 0"]

    set ticket_sla_nr [parameter::get_from_package_key -package_key intranet-helpdesk -parameter SourceForgeTrackerSlaNr -default ""]
    set ticket_sla_id [db_string ticket_sla "select min(project_id) from im_projects where project_nr = :ticket_sla_nr" -default ""]
    if {"" == $ticket_sla_id} {
	set ticket_sla_id [db_string ticket_sla "
		select	max(project_id)
		from	im_projects
		where	project_type_id in (select * from im_sub_categories([im_project_type_sla])) and
			project_status_id in (select * from im_sub_categories([im_project_status_open]))
	" -default ""]
    }

    if {"" == $ticket_sla_id} {
	ns_log Error "im_helpdesk_sourceforge_tracker_import_sweeper: No SLA specified and no active SLA available, skipping."
	return
    }


    set tracker_ids [parameter::get_from_package_key -package_key intranet-helpdesk -parameter SourceForgeTrackerIDs -default 579555]
    set tracker_ids [string trim $tracker_ids]
    foreach tracker_id $tracker_ids {

	set url "http://sourceforge.net/api/artifact/index/tracker-id/$tracker_id/rss"
	if { [catch {
            set xml [ns_httpget $url]
        } err_msg] } {
            ns_log Error "im_helpdesk_sourceforge_tracker_import_sweeper: Error retreiving file: $err_msg"
            db_string log "select acs_log__debug('im_helpdesk_sourceforge_tracker_import_sweeper', 'Error retreiving rss: [ns_quotehtml $err_msg].')"
            return
        }

	# Parse the XML file
	set tree [xml_parse -persist $xml]
	set rss_node [xml_doc_get_first_node $tree]
	set root_name [xml_node_get_name $rss_node]
	if { ![string equal $root_name "rss"] } {
	    ns_log Error "im_helpdesk_sourceforge_tracker_import_sweeper: Expected 'rss' as root node of xml file, found: '$root_name'"
	    return
	}

	set channel_nodes [xml_node_get_children $rss_node]
	set channel_ctr 0
	foreach channel_node $channel_nodes {

	    if {[catch {set channel_title [[$channel_node selectNodes {title}] text]} err_msg]} { set channel_title "unknown title" }
	    if {[catch {set channel_link [[$channel_node selectNodes {link}] text]} err_msg]} { set channel_link "" }
	    if {[catch {set channel_description [[$channel_node selectNodes {description}] text]} err_msg]} { set channel_description "" }
	    if {[catch {set channel_language [[$channel_node selectNodes {language}] text]} err_msg]} { set channel_language "en_US" }
	    if {[catch {set channel_copyright [[$channel_node selectNodes {copyright}] text]} err_msg]} { set channel_copyright "" }
	    if {[catch {set channel_pubDate [[$channel_node selectNodes {pubDate}] text]} err_msg]} { set channel_pubDate "" }
	    if {[catch {set channel_lastBuildDate [[$channel_node selectNodes {lastBuildDate}] text]} err_msg]} { set channel_lastBuildDate "" }

	    # Go through each item
	    #   <item>
	    #           <title>Get a sneak preview of ]po[ V3.4</title>
	    #           <link>http://po34demo.dnsalias.com</link>
	    #           <description>New navigation elements ...</description>
	    #           <guid isPermaLink="false">{2b5d3671-6aa5-6089-4b70-ca11648f2dcf}</guid>
	    #           <pubDate>Thu, 26 Jun 2008 09:55:42 GMT</pubDate>
	    #   </item>

	    set item_nodes [xml_node_get_children $channel_node]
	    set item_ctr 0
	    foreach item_node $item_nodes {

		if {$item_ctr > 10} { continue }

		if {[catch {set item_title [[$item_node selectNodes {title}] text]} err_msg]} { set item_title "" }
		if {[catch {set item_link [[$item_node selectNodes {link}] text]} err_msg]} { set item_link "" }
		if {[catch {set item_guid [[$item_node selectNodes {guid}] text]} err_msg]} { set item_guid "" }
		if {[catch {set item_author [[$item_node selectNodes {author}] text]} err_msg]} { set item_author "" }
		if {[catch {set item_description [[$item_node selectNodes {description}] text]} err_msg]} { set item_description "" }
		if {[catch {set item_pubDate [[$item_node selectNodes {pubDate}] text]} err_msg]} { set item_pubDate "" }
		if {[catch {set item_content [[$item_node selectNodes {content:encoded}] text]} err_msg]} { set item_content "" }
		if {[catch {set item_comments [[$item_node selectNodes {comments}] text]} err_msg]} { set item_comments "" }

		# Extract the SF artifact_id from title and skip items without ID
		if {![regexp {^([0-9]+) - (.*)} $item_title match item_artifact_id item_title]} { continue }

		# Extract status, priority etc. that are part of the "content"
		set item_status ""
		set item_category ""
		set item_priority ""
		regexp {Status\: ([a-zA-Z]+)} $item_content match item_status
		regexp {Category\: ([a-zA-Z]+)} $item_content match item_category
		regexp {Priority\: ([0-9]+)} $item_content match item_priority

		ns_log Notice "im_helpdesk_sourceforge_tracker_import_sweeper: artifact_id=$item_artifact_id, title=$item_title, link=$item_link, guid=$item_guid, author=$item_author, pubData=$item_pubDate, category=$item_category, status=$item_status, prio=$item_priority, descr=$item_description, content=$item_content, comments=$item_comments"

		# Ticket Type: All tickets are bug requests...
		set ticket_type_id [im_ticket_type_bug_request]

		# Ticket Status: Translate from SF states to ]po[
		set ticket_status_id [im_ticket_status_open]
		switch [string tolower $item_status] {
		    open { set ticket_status_id [im_ticket_status_open] }
		    closed { set ticket_status_id [im_ticket_status_closed] }
		    deleted { set ticket_status_id [im_ticket_status_deleted] }
		    pending { set ticket_status_id [im_ticket_status_waiting_for_other] }
		}

		# Ticket Priority
		set ticket_priority_id [db_string ticket_prio "select min(category_id) from im_categories where category_type = 'Intranet Ticket Priority' and category = :item_priority" -default ""]

		# Make sure there is a user for the item_author
		set item_author_id [db_string user_id "select party_id from parties where lower(email) = lower(:item_author)" -default 0]
		if {0 == $item_author_id} {
		    # Doesn't exist yet - let's create it
		    set system_url ""
		    set author_first_names ""
		    set author_last_name ""
		    if {[regexp {([^\@]+)\@.*} $item_author match prefix]} { 
		        set author_first_names $prefix
		        set author_last_name $prefix
		    }
		    array set creation_info [auth::create_user \
						 -email $item_author \
						 -url $system_url \
						 -verify_password_confirm \
						 -first_names $author_first_names \
						 -last_name $author_last_name \
						 -screen_name "$author_first_names $author_last_name" \
						 -username "$author_first_names $author_last_name" \
						 -password $author_first_names \
						 -password_confirm $author_first_names \
						]

		    set item_author_id [db_string user_id "select party_id from parties where lower(email) = lower(:item_author)" -default 0]

		}

		# Default if there was an error creating a new user
		if {!$item_author_id} {
		    # create user didn't succeed...
		    set item_author_id $system_owner_id
		}

		set ticket_id [db_string ticket_id "select min(project_id) from im_projects where project_type_id = [im_project_type_ticket] and project_nr = :item_artifact_id" -default ""]
		if {"" == $ticket_id} {
		    set ticket_id [im_ticket::new \
				       -creation_user $item_author_id \
				       -ticket_customer_contact_id $item_author_id \
				       -ticket_sla_id $ticket_sla_id \
				       -ticket_name $item_title \
				       -ticket_nr $item_artifact_id \
				       -ticket_customer_contact_id "" \
				       -ticket_type_id $ticket_type_id \
				       -ticket_status_id $ticket_status_id \
				       -ticket_note $item_content \
				      ]
		}

		db_dml update_projects "update im_projects set
				parent_id = :ticket_sla_id,
				project_name = :item_title
		       where project_id = :ticket_id
		"

		db_dml update_tickets "update im_tickets set
				ticket_customer_contact_id = :item_author_id,
				ticket_prio_id = :ticket_priority_id,
				ticket_description = :item_content
		       where ticket_id = :ticket_id
		"

		im_audit -object_id $ticket_id

                # if {[catch {set item_link [[$item_node selectNodes {link}] text]} err_msg]} { set item_link "" }
                # if {[catch {set item_guid [[$item_node selectNodes {guid}] text]} err_msg]} { set item_guid "" }
                # if {[catch {set item_description [[$item_node selectNodes {description}] text]} err_msg]} { set item_description "" }
                # if {[catch {set item_pubDate [[$item_node selectNodes {pubDate}] text]} err_msg]} { set item_pubDate "" }		

		incr item_ctr
	    }
	    
	    incr feed_ctr
	}
    }

    ns_log Notice "im_helpdesk_sourceforge_tracker_import_sweeper: finished"
}

