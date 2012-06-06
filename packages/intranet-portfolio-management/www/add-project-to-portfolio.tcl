ad_page_contract {

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2012-01-04
    @cvs-id $Id$

} {
    program_id:integer
    {return_url ""}
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set current_user_id [ad_get_user_id]
set page_title [lang::message::lookup "" intranet-portfolio-management.Add_a_project_to_the_portfolio "Add a project to the portfolio"]
set context_bar [im_context_bar "" $page_title]

# get the current users permissions for this project
im_project_permissions $current_user_id $program_id view read write admin
if {!$write} {
    ad_return_complaint 1 "You don't have the necessary permissions to modify this program".
    ad_script_abort
}

# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

set bulk_actions [list \
	[lang::message::lookup "" intranet-portfolio-management.Add_project "Add project"] \
	add-project-to-portfolio-action.tcl \
	[lang::message::lookup "" intranet-portfolio-management.Add_project "Add project"] \
]

list::create \
    -name project_list \
    -multirow project_list \
    -key project_id \
    -row_pretty_plural "Object Types" \
    -checkbox_name checkbox \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -actions {} \
    -bulk_actions $bulk_actions \
    -bulk_action_export_vars { program_id return_url } \
    -elements {
        project_chk {
            label "<input type=\"checkbox\"
                          name=\"_dummy\"
                          onclick=\"acs_ListCheckAll('project_list', this.checked)\"
                          title=\"Check/uncheck all rows\"
                          unchecked
            >"
            display_template {
                @project_list.project_chk;noquote@
            }
        }
        edit {
            label {}
        }
        project_name {
            display_col project_name
            label "Project Name"
            link_url_eval $project_url
        }
    } -filters {
    } -groupby {
    } -orderby {
    } -formats {
        normal {
            label "Table"
            layout table
            row {
                project_chk {}
                project_name {}
            }
        }
    }


db_multirow -extend { project_url project_chk} project_list select_project_list "
	select	*
	from	im_projects p
	where	p.parent_id is null and
		p.project_status_id in (select * from im_sub_categories ([im_project_status_open])) and
		p.project_type_id not in ([im_project_type_task], [im_project_type_ticket])
	order by
		lower(project_name)
" {
    set project_url [export_vars -base "/intranet/projects/view" {project_id}]
    set project_chk "<input type=\"checkbox\"
		name=\"project_id\"
		value=\"$project_id\"
		id=\"project_list,$project_id\"
		unchecked
	>
    "

}


ad_return_template
