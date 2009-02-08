ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {orderby "first_names,asc"}
    {format "normal"}
    {search_id:integer ""}
    {query ""}
    {page:optional}
    {page_size:integer ""}
    {aggregate_attribute_id ""}
    {aggregate_extend_id:multiple ""}
    {extend_values:optional ""}
    {extended_columns:optional ""}
    {return_url ""}
    {category_id ""}
}

if {$search_id eq ""} {
    # We don't have a search, load the default search_id
    set search_id [db_string search_id "select object_id from acs_objects where title = '#intranet-contacts.search_person#'"]
}

set extended_columns [ns_queryget extended_columns]
set add_column       [ns_queryget add_column]
set remove_column    [ns_queryget remove_column]
if { $extended_columns ne "" && $remove_column ne "" } {
    set lindex_id [lsearch -exact $extended_columns $remove_column]
    if { $lindex_id >= 0 } {
	set extended_columns [lreplace $extended_columns $lindex_id $lindex_id]
    }
}
if { $add_column ne "" } {
    lappend extended_columns $add_column
}


set aggregated_p 0
if {[exists_and_not_null aggregate_attribute_id] } {
    set aggregated_p 1
} 

set extend_p 0
if { [exists_and_not_null search_id] } {
    set extend_p 1
}

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]

set valid_page_sizes [list 25 50 100 500]
if { ![exists_and_not_null page_size] || [lsearch $valid_page_sizes $page_size] < 0 } {
    set page_size [parameter::get -boolean -parameter "DefaultPageSize" -default "50"]
}

set contacts_total_count [contact::search::results_count \
    -search_id $search_id \
    -query $query \
    -category_id $category_id]

if { $aggregated_p } {
    set contacts_total_count "<a href=\"?search_id=$search_id\">$contacts_total_count</a>"
}

if { [exists_and_not_null search_id] } {
    contact::search::log -search_id $search_id
}
set search_options [lang::util::localize_list_of_lists -list [db_list_of_lists public_searches {}]]

foreach group [contact::groups -expand "all" -privilege_required "read" -include_dotlrn_p "1"] {
    lappend search_options [list [lindex $group 0] [lindex $group 1] [_ intranet-contacts.Groups]]
}

db_foreach my_searches {} {
    lappend search_options [list "${my_searches_title}" ${my_searches_search_id} [_ intranet-contacts.My_Searches]]
}
db_foreach my_lists {} {
    lappend search_options [list "${my_lists_title}" ${my_lists_list_id} [_ intranet-contacts.Lists]]
}

if { [exists_and_not_null search_id] } {
    set search_in_list_p 0
    foreach search_option $search_options {
	if { [lindex $search_option 1] eq $search_id } {
	    set search_in_list_p 1
	}
    }
    if { [string is false $search_in_list_p] } {
	set search_options [concat [list [list "&lt;&lt; [_ intranet-contacts.Search] \#${search_id} &gt;&gt;" $search_id]] $search_options]
    }
}


lang::util::localize_list_of_lists -list $search_options

set package_url [ad_conn package_url]

set form_elements {
    {search_id:integer(select_with_optgroup),optional {label ""} {options $search_options} {html {onChange "javascript:acs_FormRefresh('search')"}}}
    {query:text(text),optional {label ""}}
    {save:text(submit) {label {[_ intranet-contacts.Search]}} {value "go"}}
    {results_count:integer(inform),optional {label "&nbsp;&nbsp;<span style=\"font-size: smaller;\">[_ intranet-contacts.Results] $contacts_total_count </span>"}}
}

if { [parameter::get -boolean -parameter "ForceSearchBeforeAdd" -default "0"] } {
    if { [exists_and_not_null query] && $search_id == "" } {
	append form_elements {
	    {add_person:text(submit) {label {[_ intranet-contacts.Add_Person]}} {value "1"}}
	    {add_organization:text(submit) {label {[_ intranet-contacts.Add_Organization]}} {value "1"}}
	}
    }
}


if { $search_id ne "" && $contacts_total_count > 0 } {
    set object_type [db_string object_type "select object_type from contact_searches where search_id = :search_id"]
    if {[contact::group::mapped_p -group_id $search_id]} {
	    set recipient [contact::group::name -group_id $search_id]
	    set notifications_p [contact::group::notifications_p -group_id $search_id]
    } else {
        set recipient [contact::search::title -search_id $search_id]
        set notifications_p 0
    }

    if { $notifications_p } {
	    set label [lang::util::localize [_ intranet-contacts.Notify_recipient]]
    } else {
	    set label [lang::util::localize [_ intranet-contacts.Mail_recipient]]
    }
    if {$object_type eq "person" || $object_type eq "user"} {
        append form_elements {
	        {mail_merge_group:text(submit) {label $label} {value "1"}}
        }
    }
}

ad_form -name "search" -method "GET" -export {orderby page_size format extended_columns return_url} -form $form_elements \
    -on_request {
    } -edit_request {
    } -on_refresh {
    } -on_submit {
	if { [exists_and_not_null mail_merge_group] } {
	    ad_returnredirect [export_vars -base "message" -url {{search_id $search_id}}]
	    ad_script_abort
	}
    } -after_submit {
    }

