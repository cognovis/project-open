#    @author Matthew Geddert openacs@geddert.com
#    @creation-date 2005-05-09
#    @cvs-id $Id$

set contact_master_template [parameter::get_from_package_key -package_key "contacts" -parameter "ContactMaster" -default "/packages/intranet-contacts/lib/contact-master"]
if { $contact_master_template != "/packages/intranet-contacts/lib/contact-master" } {
    ad_return_template
    return
}
template::head::add_css -href "/resources/intranet-contacts/contacts.css"

# Set up links in the navbar that the user has access to
set name [contact::name -party_id $party_id]
if { ![exists_and_not_null name] } {
    ad_complain "[_ intranet-contacts.lt_The_contact_specified]"
}

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
set package_url [ad_conn package_url]

set page_url [ad_conn url]
set page_query [ad_conn query]

set title $name
set context [list $name]
set prefix "${package_url}${party_id}/"


set link_list [list]
if { [ad_conn user_id] != 0} {
    lappend link_list "${prefix}edit"
    lappend link_list "[_ intranet-contacts.All__Edit]"

    lappend link_list "${prefix}"
    lappend link_list "[_ intranet-contacts.Summary_View]"

    lappend link_list "${prefix}relationships"
    lappend link_list "[_ intranet-contacts.Relationships]"

    lappend link_list "${prefix}message"
    lappend link_list "[_ intranet-contacts.Message]"

    lappend link_list "${prefix}files"
    lappend link_list "[_ intranet-contacts.Files]"

    # this should be taken care of by a callback instead of embedding
    # it in this contacts page...
    if { [string is true [apm_package_enabled_p tasks]] } {
	    lappend link_list "${prefix}history" "[_ intranet-contacts.History]"
	    lappend link_list "${prefix}tasks" "[_ intranet-contacts.Tasks]"
    }
    
    lappend link_list "${prefix}mail-tracking" "[_ mail-tracking.Mail_Tracking]"
    lappend link_list "${prefix}changes" "[_ intranet-contacts.Changes]"
}

# Convert the list to a multirow and add the selected_p attribute
multirow create links label url selected_p

foreach {url label} $link_list {
    set selected_p 0

    if {[string equal $page_url $url]} {
        set selected_p 1
        if { $url != "/contacts/contact" } {
            set context [list [list [contact::url -party_id $party_id] $name] $label]
        }
    }

    multirow append links $label [subst $url] $selected_p
}

set navbar [list]
set navbar_ul ""
foreach {url label} $link_list {
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
	    append navbar_ul "<li class=selected><a href=$url title=\"Go to $label\" class=navbar_selected>$label</a></li>\n"
    } else {
	    append navbar_ul "<li class=unselected><a href=$url title=\"Go to $label\" class=navbar_unselected>$label</a></li>\n"
    }

}

set contacts_navbar_html "
  <div id=navbar_sub_wrapper>
    <ul id=navbar_sub>
    $navbar_ul
    </ul>
  </div>
"

 
if { [lsearch [list person user] [contact::type -party_id $party_id]] >= 0 } {
    set public_url [acs_community_member_url -user_id $party_id]
    lappend link_list "${prefix}message"
    lappend link_list "[_ intranet-contacts.Mail]"
} else {
    set public_url ""
}

if {$public_url ne ""} {
    lappend link_list "@public_url@" [_ intranet-contacts.Public_Page]
}
ad_return_template
