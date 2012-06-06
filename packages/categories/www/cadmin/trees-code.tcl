ad_page_contract {

    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2005-06-05
    @cvs-id $Id$

} {
    {locale ""}
    tree_id:multiple
}

set user_id [auth::require_login]
permission::require_permission -object_id [ad_conn package_id] -privilege admin

set page_title "[_ categories.code_export]"
set context_bar [list [list ".?[export_vars -no_empty {locale}]" "[_ categories.cadmin]"] $page_title]

multirow create trees tree_id
foreach tid $tree_id {
    multirow append trees $tid
}

ad_return_template
