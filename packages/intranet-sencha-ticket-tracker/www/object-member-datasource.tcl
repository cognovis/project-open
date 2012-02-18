
# Tell TCL to parse HTTP session parameters, check for data type
# and to map these parameters into local variables.
ad_page_contract {
    @author frank.bergmann@project-open.com
} {
    { object_id_one:integer "" }
    { object_id_two:integer "" }
    { start:integer 0}
    { limit:integer 10}
}

# Defines a small private error message specific to this script
ad_proc -private err {msg} {
    doc_return 200 "application/json" "{\n\"success\": \"false\",\n\"message\": \"$msg\"\n}"   
    ad_script_abort
}

# Check that object_id has been specified.
# ad_page_contract wouldn't return a JSON error message...
if {"" == $object_id_one && "" == $object_id_two} {
    err "You need to specify 'object_id_one' or 'object_id_two"
}

if {"" != $object_id_one} { set where_clause "r.object_id_one = :object_id_one" }
if {"" != $object_id_two} { set where_clause "r.object_id_two = :object_id_two" }

# Define the main SQL to check for
set sql "
	select	r.rel_id,
		r.rel_type,
		r.object_id_one,
		r.object_id_two,
		bom.object_role_id,
		bom.percentage
	from	acs_rels r
		LEFT OUTER JOIN im_biz_object_members bom ON (bom.rel_id = r.rel_id)
	where	$where_clause
"

# The AuditGrid uses pagination, so we only want to 
# return the first N elements
set limited_sql "$sql
	OFFSET $start
	LIMIT $limit
"

set json_list [list]
db_foreach limited_sql $limited_sql {

    set json_row [list]
    lappend json_row "\"rel_id\": \"$rel_id\""
    lappend json_row "\"rel_type\": \"$rel_type\""
    lappend json_row "\"object_id_one\": \"$object_id_one\""
    lappend json_row "\"object_id_two\": \"$object_id_two\""
    lappend json_row "\"object_role_id\": \"$object_role_id\""
    lappend json_row "\"percentage\": \"$percentage\""

    lappend json_list "\t\t{[join $json_row ", "]}"
}

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
