#    @author Matthew Geddert openacs@geddert.com
#    @creation-date 2005-05-09
#    @cvs-id $Id$


set contacts_master_template [parameter::get_from_package_key -package_key "contacts" -parameter "ContactsMaster" -default "/packages/intranet-contacts/lib/contacts-master"]
if { $contacts_master_template != "/packages/intranet-contacts/lib/contacts-master" } {
    ad_return_template
}
template::head::add_css -href "/resources/intranet-contacts/contacts.css"

# Set up links in the navbar that the user has access to
set package_url [ad_conn package_url]

set link_list [list]
lappend link_list "${package_url}"
lappend link_list "[_ intranet-contacts.Contacts]"
lappend link_list "contacts"


if { ![parameter::get -boolean -parameter "ForceSearchBeforeAdd" -default "0"] } {

#    lappend link_list "[export_vars -base "${package_url}/contact-add" -url {{object_type person}}]"
#    lappend link_list "[_ intranet-contacts.Add_Person]"
#    lappend link_list "add_person"

#    lappend link_list "[export_vars -base "${package_url}/contact-add" -url {{object_type im_office}}]"
#    lappend link_list "[_ intranet-contacts.Add_Organization]"
#    lappend link_list "add_im_office"


    lappend link_list "[export_vars -base "${package_url}/biz-card-add" ]"
    lappend link_list "[lang::message::lookup "" intranet-contacts.Add_Biz_Card "New Biz Card"]"
    lappend link_list "add_biz_card"

}

lappend link_list "${package_url}search"
lappend link_list "[_ intranet-contacts.Advanced_Search]"
lappend link_list "advanced_search"

lappend link_list "${package_url}searches"
lappend link_list "[_ intranet-contacts.Saved_Searches]"
lappend link_list "saved_searches"

# this should be taken care of by a callback...
if { [apm_package_enabled_p tasks] } {
    lappend link_list "${package_url}tasks"
    lappend link_list "[_ tasks.Tasks]"
    lappend link_list "tasks"
    
    lappend link_list "${package_url}processes"
    lappend link_list "[_ tasks.Processes]"
    lappend link_list "processes"
}

lappend link_list "${package_url}messages"
lappend link_list "[_ intranet-contacts.Messages]"
lappend link_list "messages"

lappend link_list "${package_url}settings"
lappend link_list "[_ intranet-contacts.Settings]"
lappend link_list "settings"

if { [permission::permission_p -object_id [ad_conn package_id] -privilege "admin"] } {
    lappend link_list "${package_url}admin/"
    lappend link_list "[_ intranet-contacts.Admin]"
    lappend link_list "admin"
}

set page_url [ad_conn url]
set page_query [ad_conn query]

set navbar [list]
set navbar_ul ""
foreach {url label id} $link_list {
    set selected_p 0

    if {[string equal $page_url $url]} {
        set selected_p 1
        if { ${url} == ${package_url} } {
	    set title [ad_conn instance_name]
        } else {
	    set title $label
	}
    }
    lappend navbar [list [subst $url] $label]

    if {$selected_p} {
	append navbar_ul "<li class='selected'><div class='navbar_selected'><a href='$url'><span>$label</span></a></div></li>\n"
    } else {
	append navbar_ul "<li class='unselected'><div class='navbar_unselected'><a href='$url'><span>$label</span></a></div></li>\n"
    }

}

set subnavbar_title ""
set contacts_navbar_html "  
        <div id='navbar_sub_wrapper'>
	    $subnavbar_title
            <ul id='navbar_sub'>
              $navbar_ul
            </ul>
         </div>
"

if { [parameter::get -boolean -parameter "ForceSearchBeforeAdd" -default "0"] } {
    if { $page_url == "${package_url}add/person" } {
	    set title [_ intranet-contacts.Add_Person]
    } elseif { $page_url == "${package_url}add/organization" } {
	    set title [_ intranet-contacts.Add_Organization]
    }
}

if { ![exists_and_not_null title] } {
    set title [ad_conn instance_name]
    set context [list]
} else {
    set context [list $title]
}

ad_return_template
