# Portlet displaying a Scrum task board in a "Release Project".
#
# Expects:
# project_id:integer

if {![info exists project_id]} {

    ad_page_contract {
	Scrum Task Board
    } {
	project_id:integer
    }
    set portlet_p 0
} else {
    set porrtlet_p 1
}


set current_user_id [ad_conn user_id]
if { ![exists_and_not_null return_url] } { set return_url [ad_return_url] }
if {![info exists project_id]} { ad_return_complaint 1 "The Scrum task board portlet requires a project_id parameter" }


im_project_permissions $current_user_id $project_id view read write admin
if {!$read} { ad_return_complaint 1 "You don't have the necessary permissions to see this objects" }

set release_states_sql "
	select	category_id, category
	from	im_categories
	where 	category_type = 'Intranet Release Status'
	order by
		sort_order,
		category
"

db_multirow -extend {pretty_name} release_states release_states_query $release_states_sql {
     set pretty_name [lang::message::lookup "" intranet-scrum.Release_State_$category_id $category]
}

set release_items_sql "
	select
		acs_object__name(object_id_two) as release_item_name,
		ri.release_status_id,
		im_category_from_id(ri.release_status_id) as release_status
	from
		im_release_items ri, 
		acs_rels r
	where 
		ri.rel_id = r.rel_id and
		r.object_id_one = :project_id
	order by
		ri.sort_order
"

db_multirow release_items release_items_query $release_items_sql


