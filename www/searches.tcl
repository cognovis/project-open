ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    orderby:optional
    {owner_id:optional}
    {format "noraml"}
} -validate {
    valid_owner_id -requires {owner_id} {
	if { $owner_id ne [ad_conn user_id] && $owner_id ne [ad_conn package_id] } {
	    if { ![parameter::get -boolean -parameter "ViewOthersSearchesP" -default "0"] && ![acs_user::site_wide_admin_p] } {
		ad_complain [_ intranet-contacts.lt_Cannot_view_others_searches]
	    }
	}
    }
}

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
if { ![exists_and_not_null owner_id] } {
    set owner_id $user_id
}

if { [parameter::get -boolean -parameter "ViewOthersSearchesP" -default "0"] || [acs_user::site_wide_admin_p] } {
    set owner_options [db_list_of_lists select_owner_options {}]
} else {
    set owner_options [list [list [_ intranet-contacts.My_Searches] $user_id]]
}

set owner_options [concat [list [list [_ intranet-contacts.Public_Searches] "${package_id}"]] $owner_options]

template::list::create \
    -name "searches" \
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
        query {
	    label {#intranet-contacts.Query#}
            display_col query;noquote
        }
        results {
	    label {#intranet-contacts.Results#}
            display_col results
            link_url_eval $search_url
        }
        action {
            label ""
            display_template {
                <a href="@searches.search_url@" class="button">#intranet-contacts.Search#</a>
                <a href="@searches.copy_url@" class="button">#intranet-contacts.Copy#</a>
                <if @searches.delete_url@ not nil>
                <a href="@searches.delete_url@" class="button">#intranet-contacts.Delete#</a>
                </if>
                <if @searches.make_public_url@ not nil>
                <a href="@searches.make_public_url@" class="button">#intranet-contacts.Make_Public#</a>
                </if>
            }
        }
    } -filters {
        owner_id {
            label "\#intranet-contacts.Owner\#"
            values $owner_options
            where_clause ""
            default_value $user_id            
        }
    } -orderby {
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

db_multirow -extend {query search_url make_public_url delete_url copy_url results search_link} -unclobber searches select_searches {} {
    set aggregated_attribute [db_string get_saved_p { } -default ""]
    if { [exists_and_not_null aggregated_attribute] } { 
	set search_link ".?search_id=$search_id&aggregate_attribute_id=$aggregated_attribute"
    } else {
	set search_link "search?search_id=$search_id"
    }
    if { $owner_id != $package_id && $admin_p } {
        set make_public_url [export_vars -base search-action -url {search_id {owner_id $package_id} {action move} return_url}]
    }
    if { $owner_id == $user_id || $admin_p } {
        set delete_url      [export_vars -base search-action -url {search_id {action delete}}]
    }
    set search_url [export_vars -base ./ -url {search_id}]
    set copy_url        [export_vars -base search-action -url {search_id {owner_id $user_id} {action copy} return_url}]

    lappend search_ids $search_id
}

# Since contact::search::results_count can if not cached required two db queries
# when this is included in the multirow code block above it can hang due to a lack
# of db pools. So it has to be done here.
template::multirow foreach searches {
#    set results [contact::search::results_count -search_id $search_id]
    set results ""
    set query   [contact::search_pretty -search_id $search_id]
}

list::write_output -name searches
