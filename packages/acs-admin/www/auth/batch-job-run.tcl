ad_page_contract {
    Manually runs a batch synchronization.
    
    @author Peter Marklund
    @creation-date 2003-09-11
} {
    authority_id:integer
}

auth::authority::get -authority_id $authority_id -array authority

set page_title "Run batch job"
set authority_page_url [export_vars -base authority { {authority_id $authority(authority_id)} }]
set context [list [list "." "Authentication"] [list $authority_page_url "$authority(pretty_name)"] $page_title]

# Fraber 110913:
# set job_id [auth::authority::batch_sync -authority_id $authority_id]
# set job_url [export_vars -base batch-job { job_id }]

set job_url ""


# --------------------------------------------------------------
# Get the paremeters for the autority
# --------------------------------------------------------------

auth::authority::get -authority_id $authority_id -array authority

# Get the implementation id and implementation pretty name
array set parameters [list]
array set parameter_values [list]

# Each element is a list of impl_ids which have this parameter
array set param_impls [list]

foreach element_name [auth::authority::get_sc_impl_columns] {
    set name_column $element_name
    regsub {^.*(_id)$} $element_name {_name} name_column
    
    set impl_params [auth::driver::get_parameters -impl_id $authority($element_name)]
    
    foreach { param_name dummy } $impl_params {
        lappend param_impls($param_name) $authority($element_name)
    }
    
    array set parameters $impl_params
    
    array set parameter_values [auth::driver::get_parameter_values \
                                    -authority_id $authority_id \
				    -impl_id $authority($element_name)]
    
}

# --------------------------------------------------------------
# Import users 
# --------------------------------------------------------------

set result [auth::ldap::batch_import::import_users [array get parameter_values] $authority_id]

# set job_id [auth::authority::batch_sync -authority_id $authority_id]

# set job_url [export_vars -base batch-job { job_id }]
