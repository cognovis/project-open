# /packages/ocntacts/www/admin/purge-user-searches.tcl

ad_page_contract {
} {
} -properties {
}

set title [_ intranet-contacts.Purge_users_searches]
set context [list $title]

ad_form -name "purge_searches" \
    -form {
	{user_id:contact_search(contact_search) {label "[_ intranet-contacts.Purge_users_searches]"} {search persons}}
    } -on_request {
    } -on_submit {
	db_list deletem { select acs_object__delete(search_id) from contact_searches where owner_id = :user_id }
	foreach name [ns_cache names util_memoize] {
	    ns_cache flush util_memoize $name
	}
    } -after_submit {
	ad_returnredirect ./
	ad_script_abort
    }

