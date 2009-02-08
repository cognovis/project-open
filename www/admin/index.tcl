ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$


} {
}

set return_url [ad_conn url]

set orderby "name"
set title "[_ intranet-contacts.lt_Contact_Administratio]"
set context {}
set package_id [ad_conn package_id]
set parameter_url [export_vars -base "/shared/parameters" {package_id {return_url "[ad_conn url]"}}]
template::list::create \
    -name "categories" \
    -multirow "categories" \
    -row_pretty_plural "[_ intranet-contacts.categories]" \
    -elements {
	    object_type {}
	    category_name {
            label {[_ intranet-core.Category]}
	        display_col category_name
        }
        member_count {
            label {[_ intranet-contacts.Contacts]}
	        display_template {
		        <a href="@categories.search_url@">@categories.member_count@</a>
	        }
        }
        category_list {
            display_template {
                <a href="@categories.list_url@" class="button">[_ intranet-contacts.List]</a>
            }
        }
        edit {
	        label {}
	        display_template {
		        <a href="@categories.edit_url@"><img src="/resources/acs-subsite/Edit16.gif" height="16" width="16" border= "0" alt="[_ acs-kernel.common_Edit]"></a></if>
	        }
	    }
        } -filters {
    } -orderby {
    }


multirow create categories category_id category_name member_count edit_url search_url list_url object_type mapped_p user_change_p

set return_url [ad_conn url]


# Supported object_types
set object_types [intranet-contacts::supported_object_types]
foreach object_type $object_types {
    set search_id($object_type) [db_string search_id "select object_id from acs_objects where title = '#intranet-contacts.search_${object_type}#'"]
}


# Deal with category based object types
set previous_object_type ""
foreach category [intranet-contacts::categories -indent_with "..." -object_types [list im_company im_office]] {
    util_unlist $category category_id category_name member_count object_type

    if {$object_type ne $previous_object_type} {
	    # Mark this object type as displayed
	    lappend displayed_object_types $object_type
        set previous_object_type $object_type
	    set object_count [contact::search::results_count -search_id $search_id($object_type)]
	    set search_url [export_vars -base "/intranet-contacts/" -url {{search_id $search_id($object_type)}}]
	    set list_url [ams::list::url -object_type $object_type -list_name $object_type]
	    multirow append categories $category_id "" $object_count "" $search_url $list_url $object_type "t" "f"
    }

    set edit_url [export_vars -base "/intranet/admin/categories/one" -url {category_id}]
    set search_url [export_vars -base "/intranet-contacts/" -url {category_id {search_id $search_id($object_type)}}]
	set list_url [ams::list::url -object_type $object_type -list_name $category_id]
    multirow append categories $category_id $category_name $member_count $edit_url $search_url $list_url "" "t" "f"
}


# Now deal with the group based ones. First the default for person
set object_type person
set list_url [ams::list::url -object_type $object_type -list_name $object_type]
set search_idch_url [export_vars -base "/intranet-contacts/" -url {{search_id $search_id(person)}}]
set member_count [db_string persons "select count(person_id) from persons"]
multirow append categories "" "" $member_count "" $search_url $list_url "Person" "t" "t"

foreach category [intranet-contacts::categories -indent_with "..." -object_types [list group]] {
    util_unlist $category category_id category_name member_count object_type

    set edit_url [export_vars -base "/intranet/admin/categories/one" -url {category_id}]
    set search_url [export_vars -base "/intranet-contacts/" -url {{category_id $category_id} {search_id $search_id(person)}}]
	set list_url [ams::list::url -object_type $object_type -list_name $category_id]
    multirow append categories $category_id $category_name $member_count $edit_url $search_url $list_url "" "t" "f"
}
