ad_page_contract {
    Set default categories
}

set project_name [bug_tracker::conn project_name]
set page_title "Default Category Setup"
set context_bar [ad_context_bar [list categories "Manage Categories"] $page_title]

array set default_configs [bug_tracker::get_default_configurations]

set options [list]

foreach name [lsort -ascii [array names default_configs]] {
    lappend options [list $name $name]
}

ad_form -name setup -cancel_url categories -form {
    {setup:text(select) {label "Choose setup"} {options $options}}
} -on_submit {
    array set config $default_configs($setup)
    
    bug_tracker::install_keywords_setup -spec $config(categories)
    ad_returnredirect categories
    ad_script_abort
}
