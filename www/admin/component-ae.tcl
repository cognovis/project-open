ad_page_contract {
    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-26
    @cvs-id $Id$
} {
    component_id:integer,optional
    {return_url "."}
}

set package_id [ad_conn package_id]

if { [info exists component_id] } {
    set page_title "Edit [bug_tracker::conn Component]"
} else {
    set page_title "Add [bug_tracker::conn Component]"
}
set context [list $page_title]

# LARS:
# I've hidden the description, because we don't use it anywhere

ad_form -name component -cancel_url $return_url -form {
    {component_id:key(acs_object_id_seq)}
    {return_url:text(hidden) {value $return_url}}
    {name:text {html { size 50 }} {label "[bug_tracker::conn Component] Name"}}
    {description:text(hidden),optional {label {Description}} {html { cols 50 rows 8 }}}
    {url_name:text,optional {html { size 50 }} {label {Name in shortcut URL}}
        {help_text "You can filter by this [bug_tracker::conn component] by viisting [ad_conn package_url]com/this-name/"}
    }
    {maintainer:search,optional
        {result_datatype integer}
        {label "Maintainer"}
        {options [bug_tracker::users_get_options]}
        {search_query {[db_map user_search]}}
    }
} -select_query {
    select component_id, 
           component_name as name, 
           description, 
           maintainer,
           url_name
    from   bt_components
    where  component_id = :component_id
} -new_data {
    db_dml component_create {}
} -edit_data {
    db_dml component_update {}
} -after_submit {
    bug_tracker::components_flush

    ad_returnredirect $return_url
    ad_script_abort
}
