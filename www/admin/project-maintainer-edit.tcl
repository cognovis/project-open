ad_page_contract {
    Pick a project maintainer

    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-26
    @cvs-id $Id$
} {
    {return_url "."}
}

set package_id [ad_conn package_id]

set page_title "Edit Project Maintainer"

set context [list $page_title]

ad_form -name project_maintainer -cancel_url $return_url -form {
    {return_url:text(hidden) {value $return_url}}
    {maintainer:search,optional
        {result_datatype integer}
        {label {Project Maintainer}}
        {options [bug_tracker::users_get_options]}
        {search_query
            {
                select distinct u.first_names || ' ' || u.last_name || ' (' || u.email || ')' as name, u.user_id
                from   cc_users u
                where  upper(coalesce(u.first_names || ' ', '')  || coalesce(u.last_name || ' ', '') || u.email || ' ' || coalesce(u.screen_name, '')) like upper('%'||:value||'%')
                order  by name
            } 
        }
    }
} -select_query {
    select maintainer from bt_projects where project_id = :package_id
} -on_submit {
    db_dml project_maintainer_update {
        update bt_projects
        set    maintainer = :maintainer
        where  project_id = :package_id
    }

    ad_returnredirect $return_url
    ad_script_abort
}
