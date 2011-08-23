ad_page_contract {
    page to insert a new audit to im_audit
    @author David Blanco (david.blanco@grupoversia.com)
    @creation-date 19/08/2011
    @cvs-id $Id$
} {
    { object_id:integer}
    { user_id "" }
	{ object_type "" }
	{ status_id "" }
	{ type_id "" }
	{ action }
	{ comment "" }
}

ns_log Notice "audit-insert: object_id=$object_id, user_id=$user_id, object_type=$object_type, status_id=$status_id, type_id=$type_id, action=$action"
# ----------------------------------------------------------------------
# Main Audit Procedure
# ----------------------------------------------------------------------

ad_proc -private im_audit_impl_nodiff { 
    -object_id:required
    {-user_id "" }
    {-object_type "" }
    {-status_id "" }
    {-type_id "" }
    {-action "after_update" }
    {-comment "" }
} {
    Creates a new audit item, no check the diference.
} {
    ns_log Notice "im_audit_impl_nodiff: object_id=$object_id, user_id=$user_id, object_type=$object_type, status_id=$status_id, type_id=$type_id, action=$action, comment=$comment"

    if {"" == $user_id} { set user_id [ad_get_user_id] }
    set peeraddr [ns_conn peeraddr]

    # Are we behind a firewall or behind a reverse proxy?
    if {"127.0.0.1" == $peeraddr} {

		# Get the IP of the browser of the user
		set header_vars [ns_conn headers]
		set x_forwarded_for [ns_set get $header_vars "X-Forwarded-For"]
		if {"" != $x_forwarded_for} {
		    set peeraddr $x_forwarded_for
		}
    }

    # Get information about the audit object
    set object_type ""
    set old_value ""
    set last_audit_id ""
    db_0or1row last_info "
	select	a.audit_value as old_value,
		o.object_type,
		o.last_audit_id
	from	im_audits a,
		acs_objects o
	where	o.object_id = :object_id and
		o.last_audit_id = a.audit_id
    "

    # Get the new value from the database
    set new_value [im_audit_object_value -object_id $object_id -object_type $object_type]

    # Calculate the "diff" between old and new value.
    # Return "" if nothing has changed:
    set diff [im_audit_calculate_diff -old_value $old_value -new_value $new_value]

    if {"" == $diff} {
    	set diff "no diff"
    }
    
	# Something has changed...
	# Create a new im_audit entry and associate it to the object.
	set new_audit_id [db_nextval im_audit_seq]
	set audit_ref_object_id ""
	set audit_note $comment
	set audit_hash ""

	db_dml insert_audit "
		insert into im_audits (
			audit_id,
			audit_object_id,
			audit_object_status_id,
			audit_action,
			audit_user_id,
			audit_date,
			audit_ip,
			audit_last_id,
			audit_ref_object_id,
			audit_value,
			audit_diff,
			audit_note,
			audit_hash
		) values (
			:new_audit_id,
			:object_id,
			im_biz_object__get_status_id(:object_id),
			:action,
			:user_id,
			now(),
			:peeraddr,
			:last_audit_id,
			:audit_ref_object_id,
			:new_value,
			:diff,
			:audit_note,
			:audit_hash
		)
	"

	db_dml update_object "
		update acs_objects set
			last_audit_id = :new_audit_id,
			last_modified = now(),
			modifying_user = :user_id,
			modifying_ip = :peeraddr
		where object_id = :object_id
	"
	
    return $diff
}
# -------------------------------------------------------------
# Security
# -------------------------------------------------------------
# ToDo: ¿Security actiosn?


# -------------------------------------------------------------
# Insert new record in im_audits
# -------------------------------------------------------------
set result "true"
if {[catch {
    set err_msg [im_audit_impl_nodiff -user_id $user_id -object_id $object_id -object_type $object_type -status_id $status_id -action $action -comment $comment]
} err_msg]} {
    ns_log Notice "audit-insert Error: Error executing im_audit_impl_nodiff: $err_msg"
    set result "false"
}

doc_return 200 "text/html" "{
	\"result\": {
		\"success\":	$result,
		\"message\":	$err_msg
    	}
}"