# Set a sub-project's customer field to the one of its parent


ad_page_contract {
    Set a sub-project's customer field to the one of its parent
} {
    project_id:integer
    return_url
}

set parent_project_id [db_string parent "
	select	parent.project_id
	from	im_projects parent,
		im_projects child
	where	child.project_id = :project_id and
		parent.tree_sortkey = tree_root_key(child.tree_sortkey)
"]

db_dml fix_company_id "
	update im_projects
	set company_id = (select company_id from im_projects where project_id = :parent_project_id)
	where project_id = :project_id
"

im_audit -object_id $project_id
ad_returnredirect $return_url
