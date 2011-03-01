#    @author Matthew Geddert openacs@geddert.com
#    @creation-date 2005-05-09
#    @cvs-id $Id: master.tcl,v 1.1 2009/03/16 17:44:54 phast Exp $


# Add special CSS to head?
# template::head::add_css -href "/resources/intranet-contacts/contacts.css"

# Set up links in the navbar that the user has access to
set package_url [ad_conn package_url]
set page_url [ad_conn url]
set page_query [ad_conn query]

set link_list [list]
lappend link_list "${package_url}"
lappend link_list "[_ intranet-contacts.Contacts]"
lappend link_list "contacts"


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
