ad_page_contract {
    Page that lists patches in this Bug Tracker
    project.

    @author Peter Marklund (peter@collaboraid.biz)
    @date 2002-09-10
    @cvs-id $Id$
} {
    {component_id:integer,optional}
    {apply_to_version:integer,optional}
    {status:trim,optional}
}

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

set page_title "Patches" 
set context [list $page_title]

# TODO: Use bug_tracker::patch_status_pretty for pretty state (problem with the filter, but it can be done)

template::list::create \
    -name patches \
    -multirow patches \
    -elements {
        patch_number {
            label "Patch \#"
            display_template {\#@patches.patch_number@}
            html { align right }
        }
        summary {
            label "Summary"
            link_url_eval {[export_vars -base patch { patch_number }]}
        }
        status {
            label "Status"
            display_eval {[string totitle $status]}
        }
        apply_to_version_name {
            label "Apply To"
            display_template {
                <if @patches.apply_to_version_name@ not nil>@patches.apply_to_version_name@</if>
                <else><i>Undecided</i></else>
            }
        }
        component_name {
            label "Component"
        }
        creation_date_pretty {
            label "Submitted"
        }
    } -filters {
        status {
            label "Status"
            values {[db_list_of_lists select_states {}]}
            where_clause {[db_map states_where_clause]}
        }
        apply_to_version {
            label "Apply to version"
            values {[db_list_of_lists select_versions {}]}
            where_clause {[db_map apply_to_version_where_clause]}
            null_where_clause {[db_map apply_to_version_null_where_clause]}
            null_label {Undecided}
        }
        component_id {
            label "Component"
            values {[db_list_of_lists select_components {
            }]}
            where_clause {[db_map component_where_clause]}
        }
    }


db_multirow patches select_patches {} 

