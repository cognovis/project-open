
ad_page_contract {
    @author frank.bergmann@project-open.com
} {
    { node 0}
}

set project_sql "
	select	*
	from	im_projects p
	where	p.parent_id is null and
		p.project_type_id = 2502
"

set json_list [list]
db_foreach projects $project_sql {
    lappend json_list "\t{\"id\": \"$project_id\", \"project_id\": \"$project_id\", \"project_name\": \"$project_name\"}"
}

doc_return 200 "application/json" "{\"success\": \"true\",\n\"message\": \"Data loaded\",\n\"data\": \[\n[join $json_list ",\n"]\n\t\]
}"
