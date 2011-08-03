
# Tell TCL to parse HTTP session parameters, check for data type
# and to map these parameters into local variables.
ad_page_contract {
    @author frank.bergmann@project-open.com
} {
    { object_id:integer "" }
    { start:integer 0}
    { limit:integer 10}
    { sort "" }
}

# Defines a small private error message specific to this script
ad_proc -private err {msg} {
    doc_return 200 "application/json" "{\n\"success\": \"false\",\n\"message\": \"$msg\"\n}"   
    ad_script_abort
}

# Check that object_id has been specified.
# ad_page_contract wouldn't return a JSON error message...
if {"" == $object_id} {
    err "You need to specify 'object_id'"
}

if {"" == $sort} {
    set sort "\[{\"property\":\"audit_date\",\"direction\":\"DESC\"}\]"
}

# Parse the "sort" JSON
ns_log Notice "object-audit-datasource: object_id=$object_id, start=$start, limit=$limit, sort=$sort"
array set parsed_json [util::json::parse $sort]
ns_log Notice "object-audit-datasource: parsed_json: [array get parsed_json]"
set json_list [lindex $parsed_json(_array_) 0]
ns_log Notice "object-audit-datasource: json_list=$json_list"
set json_sorters [lindex $json_list 1]
ns_log Notice "object-audit-datasource: json_sorters=$json_sorters"
array set sorter_hash $json_sorters
set property $sorter_hash(property)
set direction $sorter_hash(direction)


# if {![string is alnum $property]} { err "'property'='$property' is not alphanum" }
# if {![string is alnum $direction]} { err "'direction'='$direction' is not alphanum" }

# Define the main SQL to check for
set sql "
	select	a.*,
		t.ticket_queue_id_pretty
	from	im_audits a,
		(select	max(audit_id) as audit_id,
			audit_object_status_id,
			ticket_queue_id_pretty
		from	(select	*,
				CASE WHEN 463=ticket_queue_id THEN '' ELSE ticket_queue_id END as ticket_queue_id_pretty
			from	(select	audit_id,
					audit_object_status_id,
					substring(audit_value from 'ticket_queue_id\\t(\[^\\n\]*)') as ticket_queue_id
				from	im_audits
				where	audit_object_id = :object_id
				) t
			) t
		group by
			audit_object_status_id,
			ticket_queue_id_pretty
		) t
	where	a.audit_id = t.audit_id
	order by $property $direction
"



# The AuditGrid uses pagination, so we only want to 
# return the first N elements
set limited_sql "$sql
	OFFSET $start
	LIMIT $limit
"

set cnt 0
set json_list [list]
db_foreach limited_sql $limited_sql {

    # Standard audit fields that are identical amongst all object types
    set json_row [list]
    lappend json_row "\"id\": \"$audit_id\""
    lappend json_row "\"audit_id\": \"$audit_id\""
    lappend json_row "\"audit_object_id\": \"$audit_object_id\""
    lappend json_row "\"audit_action\": \"$audit_action\""
    lappend json_row "\"audit_user_id\": \"$audit_user_id\""
    lappend json_row "\"audit_date\": \"$audit_date\""
    lappend json_row "\"audit_ip\": \"$audit_ip\""
    lappend json_row "\"audit_object_status_id\": \"$audit_object_status_id\""

    # The "audit_value" contains a list of key-value pairs specific
    # to the object type being audited. We just return them as JSON 
    # and leave parsing and interpretation to the Sencha GUI.
    set lines [split $audit_value "\n"]
    foreach line $lines {
	set el [split $line "\t"]
	set key [lindex $el 0]
	set val [lindex $el 1]
	lappend json_row "\"$key\": \"[im_quotejson $val]\""
    }

    lappend json_list "{[join $json_row ", "]}"
    incr cnt
}

# Update the ticket with the count and reset 
# the "dirty" flag, so that the sweeper will do its work
db_dml update_ticket_actions "
	update im_tickets set 
		ticket_action_count = :cnt,
		ticket_resolution_time_dirty = null
	where ticket_id = :object_id
"

# Re-calculate the resolution time of the ticket
im_sla_ticket_solution_time_sweeper -ticket_id $object_id -debug_p 1


# Paginated Sencha grids require a "total" amount in order to know
# the total number of pages
set total_count [db_string total "select count(*) from ($sql) t"]

# Return a JSON structure suitable for Sencha.
set success "\"success\": \"true\""
set message "\"message\": \"Data loaded\""
set total "\"total\": $total_count"
doc_return 200 "application/json" "{
	$success,
	$message,
	$total,
	\"data\": \[
[join $json_list ",\n"]
	\]
}"

