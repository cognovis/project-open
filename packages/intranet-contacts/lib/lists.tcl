ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {delete_list_id:integer ""}
    {confirm_p:boolean "0"}
} -validate {
    valid_set_public_p -requires {delete_list_id} {
	if { [db_string get_creator { select creation_user from acs_objects where object_id = :delete_list_id }] ne [ad_conn user_id] || ![contact::owner_p -object_id $delete_list_id -owner_id [ad_conn user_id]] } {
	    if { ![permission::permission_p -object_id [ad_conn package_id] -privilege "admin"] } {
		ad_complain "[_ intranet-contacts.You_can_only_delete_list_you_created_and_own]"
	    }
	}
    }
}



set package_id [ad_conn package_id]
set package_url [ad_conn package_url]
set user_id [ad_conn user_id]
set admin_p [permission::permission_p -object_id $package_id -privilege "admin"]
set url [ad_conn url]

if { $delete_list_id ne "" } {
    if { [string is true $confirm_p] } {
	contact::owner_delete_all -object_id $delete_list_id
	contact::list::delete -list_id $delete_list_id
	ad_returnredirect [ad_conn url]
	ad_script_abort
    } else {
	set no_url [export_vars -base $url]
	set yes_url [export_vars -base $url -url {delete_list_id {confirm_p 1}}]
    }
}




ad_form \
    -name "add_list" \
    -method "POST" \
    -form {
	{title:text(text) {label ""} {html {size 30 maxlength 255}}}
	{add:text(submit) {label "[_ intranet-contacts.Add_List]"}}
    } -validate {
	{title
	    { ![expr { [string trim $title] eq "" }] }
	    {[_ intranet-contacts.Required]}
	}
	{title
	    { ![db_0or1row list_already_exists " select 1 from contact_lists, acs_objects, contact_owners where contact_lists.list_id = acs_objects.object_id and acs_objects.object_id = contact_owners.object_id and acs_objects.package_id = :package_id and contact_owners.owner_id in (:user_id,:package_id) and acs_objects.title = '[db_quote [string trim $title]]' limit 1 "] }
	    {[_ intranet-contacts.List_already_exists_with_this_name]}
	}
    } -on_submit {
	set title [string trim $title]
	set list_id [contact::list::new -title $title]
	contact::owner_add -object_id $list_id -owner_id [ad_conn user_id]
    } -after_submit {
	ad_returnredirect [ad_conn url]
	ad_script_abort
    }



template::list::create \
    -name "lists" \
    -row_pretty_plural "[_ intranet-contacts.lists]" \
    -elements {
        title {
	    label {[_ intranet-contacts.List]}
	    link_url_eval $list_url
	}
        sharing {
	    label {[_ intranet-contacts.Sharing]}
	    link_url_eval $sharing_url
        }
        members {
	    label {[_ intranet-contacts.Members]}
        }
        action {
            label ""
            display_template {
                <a href="@lists.delete_url@"><img src="/resources/acs-subsite/Delete16.gif" height="16" width="16" /></a>
            }
        }
    }



db_multirow -extend {list_url delete_url sharing sharing_url} -unclobber lists select_lists {} {
    if { $members eq "" } { set members "0" }
    set list_url [export_vars -base ${package_url} -url {{search_id  ${list_id}}}]
    set delete_url [export_vars -base "lists" -url {{delete_list_id $list_id}}]
    set sharing_url [export_vars -base "sharing" -url {{object_id $list_id} {return_url $url}}]

    if { [contact::owner_p -object_id $list_id -owner_id $package_id] } {
	set sharing "[_ intranet-contacts.Public]"
    } else {
	set count [contact::owner_count -object_id $list_id]
	if { $count > 1 } {
	    set sharing "[_ intranet-contacts.Shared]"
	} else {
	    set sharing "[_ intranet-contacts.Private]"
	}
    }
}
