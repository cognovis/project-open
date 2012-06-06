# Called as a component

if {![info exists component_name]} { set component_name "Undefined Component" }


set sql "
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
db_foreach project_queue $sql {
    lappend values [list $project_status $cnt]
}
set project_portfolio_html [im_dashboard_project_portfolio -values $values]
