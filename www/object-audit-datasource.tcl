ad_page_contract {
    @author frank.bergmann@project-open.com
} {
    { object_id "" }
}

if {"" == $object_id} {
    doc_return 200 "application/json" "{\n\"success\": \"false\",\n\"message\": \"You need to specify 'object_id'\"\n}"   
}

set sql "
	select	*
	from	im_audits a
	where	a.audit_object_id = :object_id
	order by audit_date
"

set json_list [list]
db_foreach sql $sql {

    # Add the constant fields to the columns
    set json_row [list]
    lappend json_row "\"id\": \"$audit_id\""
    lappend json_row "\"audit_id\": \"$audit_id\""
    lappend json_row "\"audit_object_id\": \"$audit_object_id\""
    lappend json_row "\"audit_action\": \"$audit_action\""
    lappend json_row "\"audit_user_id\": \"$audit_user_id\""
    lappend json_row "\"audit_date\": \"$audit_date\""
    lappend json_row "\"audit_ip\": \"$audit_ip\""
    lappend json_row "\"audit_object_status_id\": \"$audit_object_status_id\""

    set lines [split $audit_value "\n"]
    foreach line $lines {
	set el [split $line "\t"]
	set key [lindex $el 0]
	set val [lindex $el 1]
	lappend json_row "\"$key\": \"[ns_quotehtml $val]\""
    }

    lappend json_list "{[join $json_row ", "]}"
}

doc_return 200 "application/json" "{\"success\": \"true\",\n\"message\": \"Data loaded\",\n\"data\": \[\n[join $json_list ",\n"]\n\t\]
}"
