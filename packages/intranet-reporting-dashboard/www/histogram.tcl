
# Called as a component

if {![info exists component_name]} { set component_name "Undefined Component" }
if {![info exists cube_name]} { set  cube_name "finance" }
if {![info exists start_date]} { set start_date "" }
if {![info exists end_date]} { set end_date "" }
if {![info exists cost_type_id]} { set cost_type_id "3700" }
if {![info exists top_vars]} { set top_vars "year" }
if {![info exists left_vars]} { set left_vars "customer_name" }
if {![info exists return_url]} { set return_url ""}

set sql2 "
        select
		count(*) as cnt,
		project_status_id,
                im_category_from_id(project_status_id) as project_status
        from
		im_projects p
	where
		p.parent_id is null
        group by 
		project_status_id
	order by
		project_status_id
"


set values [list]
db_foreach project_queue $sql2 {
    lappend values [list $project_status $cnt]
}
set histogram_html [im_dashboard_histogram -values $values]

