
ad_page_contract {
    @author frank.bergmann@project-open.com
} {
    { sla_id:integer ""}
}

# Returns 0 if the user isn't logged in,
# which defaults to the "guest" user without privileges.
set user_id [auth::get_user_id]


# Do we select tickets only for a specified SLA?
set sla_where "and p.parent_id = :sla_id" 
if {"" == $sla_id} { set sla_where "" }

set ticket_sql "
	select	*,
		im_name_from_user_id(o.creation_user) as creation_user_name,
		ticket_description as excerpt
	from	im_projects p,
		im_tickets t,
		acs_objects o
	where	t.ticket_id = p.project_id and
		t.ticket_id = o.object_id
		$sla_where
	LIMIT 10
"

set valid_vars {excerpt}

set json_list [list]
set cnt 0
db_foreach tickets $ticket_sql {
	set json_row [list]
	lappend json_row "\"id\": \"$ticket_id\""
	lappend json_row "\"threadid\": \"$ticket_id\""
	lappend json_row "\"text\": \"$project_name\""
	lappend json_row "\"title\": \"$project_name\""
	lappend json_row "\"forumtitle\": \"$project_name\""
	lappend json_row "\"forumid\": \"$parent_id\""
	lappend json_row "\"author\": \"$creation_user_name\""
	lappend json_row "\"replycount\": \"10\""
	lappend json_row "\"lastpost\": \"$ticket_creation_date\""
	lappend json_row "\"lastposter\": \"$creation_user_name\""

	foreach v $valid_vars {
		eval "set a $$v"
		regsub -all {\n} $a {\n} a
		regsub -all {\r} $a {} a
		lappend json_row "\"$v\": \"[ns_quotehtml $a]\""
	}

	lappend json_list "{[join $json_row ", "]}"
	incr cnt
}


doc_return 200 "application/json" "{\"success\": \"true\",\n\"message\": \"Data loaded\",\n\"total\": \"$cnt\",\n\"data\": \[\n[join $json_list ",\n"]\n\t\]\n}"

