ad_page_contract {
    Pick a project maintainer

    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-26
    @cvs-id $Id$
} {
    {return_url "."}
}

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]

set page_title "Edit Project"
set context [list $page_title]

ad_form -name project -cancel_url $return_url -form {
    package_id:key
    {return_url:text(hidden) {value $return_url}}
    {name:text {html { size 50 }} {label "Project Name"}
        {help_text {This is also the name of this package in the site map}}
    }
    {description:text(hidden),optional {label "Description"} {html { cols 50 rows 8 }}
        {help_text {This isn't actually used anywhere at this point. Sorry.}}
    }
    {email_subject_name:text,optional {html { size 50 }} {label "Notification tag"}
        {help_text {This text will be included in square brackets at the beginning of all notifications, for example \[OpenACS Bugs\]}}
    }
    {maintainer:search,optional
        {result_datatype integer}
        {label {Project Maintainer}}
        {options [bug_tracker::users_get_options]}
        {search_query {[db_map dbqd.acs-tcl.tcl.community-core-procs.user_search]}}
    }
} -select_query_name project_select -edit_data {
    db_transaction {
        db_dml project_info_update {}

        bug_tracker::set_project_name $name
    }
    site_nodes_sync
    bug_tracker::get_project_info_flush
} -after_submit {
    ad_returnredirect $return_url
    ad_script_abort
}

