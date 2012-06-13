ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    orderby:optional
    {owner_id:optional}
    {format "normal"}
    page:optional
} -validate {
}

set page_title [_ intranet-contacts.Search_List]



set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
if { ![exists_and_not_null owner_id] } {
    set owner_id $user_id
}

template::list::create \
    -name "searches" \
    -key search_id \
    -page_size 10 \
    -page_flush_p 0 \
    -page_query_name select_searches_pagination \
    -multirow "searches" \
    -row_pretty_plural "[_ intranet-contacts.searches]" \
    -selected_format $format \
    -key search_id \
    -elements {
        title {
	    label {[_ intranet-contacts.Title]}
	    display_template {
                <a href="@searches.search_link@">@searches.title@</a>
            }
	}
	owner {
	    label {[_ intranet-contacts.Owner]}
	    display_template {
		by @searches.owner@
	    }
	}
        query {
	    label { [_ intranet-contacts.Query]}
            display_col query;noquote
        }
        results {
	    label {[_ intranet-contacts.Results]}
            display_col results
            link_url_eval $search_url
        }
        action {
            label ""
            display_template {
                <a href="ext-search-options?search_id=@searches.search_id@" class="button">Default Extend Options</a>
                <a href="attribute-list?search_id=@searches.search_id@" class="button">Default Attributes</a>
            }
        }
    } -orderby {
	default_value title
	title {
	    label {[_ intranet-contacts.Title]}
	    orderby_desc "order_title desc"
	    orderby_asc "order_title asc"
	}
	owner {
	    label {[_ intranet-contacts.Owner]}
	    orderby_desc "owner_id desc, order_title asc"
	    orderby_asc "owner_id asc, order_title asc"
	}
    } -formats {
	normal {
	    label "[_ intranet-contacts.Table]"
	    layout table
	    row {
	    }
	}
	csv {
	    label "CSV"
	    output csv
	    row {
                title {}
                results {}
	    }
	}
    }


set return_url [export_vars -base searches -url {owner_id}]
set search_ids [list]
set admin_p [permission::permission_p -object_id $package_id -privilege "admin"]

db_multirow -extend {query search_url make_public_url delete_url copy_url results owner search_link} -unclobber searches select_searches {} {

    set aggregated_attribute [db_string get_saved_p { } -default ""]
    if { [exists_and_not_null aggregated_attribute] } {
        set search_link ".?search_id=$search_id&aggregate_attribute_id=$aggregated_attribute"
    } else {
	set search_link "search?search_id=$search_id"
    }

    set search_url [export_vars -base ../ -url {search_id}]
    set owner [contact::name -party_id $search_owner_id]
    if { [empty_string_p $owner] } {
	set owner "Public"
    }

    lappend search_ids $search_id
}

# Since contact::search::results_count can if not cached required two db queries
# when this is included in the multirow code block above it can hang due to a lack
# of db pools. So it has to be done here.
template::multirow foreach searches {
    set results [contact::search::results_count -search_id $search_id]
    set query   [contact::search_pretty -search_id $search_id]
}

list::write_output -name searches
