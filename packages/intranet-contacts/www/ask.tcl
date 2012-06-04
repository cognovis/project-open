ad_page_contract {
    Confirm upload in delivery folder.

    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2006-05-15
} {
    {group_ids ""}
    object_id_two
    role_two
} -properties {
    context:onevalue
    page_title:onevalue
}

set user_id [auth::require_login]
set page_title "[_ intranet-contacts.person_or_organization]"
set context [list $page_title]

set confirm_options [list [list "[_ intranet-contacts.Person]" t] [list "[_ intranet-contacts.Organization]" f]]

ad_form -name upload_confirm -action ask -export {cancel_url return_url} -form {
    {group_ids:text(hidden),optional {value $group_ids}}
    {object_id_two:integer(hidden) {value $object_id_two}}
    {role_two:text(hidden) {value $role_two}}
    {confirmation:text(radio) {label "[_ intranet-contacts.person_or_organization]"} {options $confirm_options} {value f}}
} -edit_request {
} -after_submit {
    set package_url [ad_conn package_url]
    if {$confirmation} {
	ad_returnredirect [export_vars -base "${package_url}/add/person" -url {group_ids object_id_two role_two}]
    } else {
	ad_returnredirect [export_vars -base "${package_url}/add/organization" -url {group_ids object_id_two role_two}]
    }
    ad_script_abort
}

ad_return_template
