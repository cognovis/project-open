ad_page_contract {
    Initial project setup
}

set project_name [bug_tracker::conn project_name]
set page_title "Initial Setup"
set context_bar [ad_context_bar $page_title]

array set default_configs [bug_tracker::get_default_configurations]

set options [list]

foreach name [lsort -ascii [array names default_configs]] {
    lappend options [list $name $name]
}
lappend options [list "Custom" "custom"]

ad_form -name setup -cancel_url . -form {
    {setup:text(select) {label "Choose setup"} {options $options}}
} -on_submit {
    if { [info exists default_configs($setup)] } {
        array set config $default_configs($setup)
        
        bug_tracker::delete_all_project_keywords
        bug_tracker::install_keywords_setup -spec $config(categories)
        bug_tracker::install_parameters_setup -spec $config(parameters)
    }
} -after_submit {
    ad_returnredirect .
    ad_script_abort
}
