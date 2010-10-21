ad_page_contract {
    View one event
    
    @author Ben Adida (ben@openforce.net)
    @creation-date April 09, 2002
    @cvs-id $Id$
} {
    cal_item_id:integer
    {return_url [ad_return_url]}
}

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]

permission::require_permission -object_id $cal_item_id -privilege read

calendar::item::get -cal_item_id $cal_item_id -array cal_item

# Honor the related link redirection facility long implemented in acs-events, but
# ignored by calendar.
if { $cal_item(redirect_to_rel_link_p) eq "t" &&
     $cal_item(related_link_url) ne "" } {
    ad_returnredirect $cal_item(related_link_url)
    ad_script_abort
}

set write_p [permission::write_permission_p -object_id $cal_item_id -creation_user $cal_item(creation_user)]

# Attachments?
if {$cal_item(n_attachments) > 0} {
    set item_attachments [attachments::get_attachments -object_id $cal_item(cal_item_id) -return_url [ad_return_url]]
} else {
    set item_attachments [list]
}

# no time?
set cal_item(no_time_p) [expr {!$cal_item(time_p)}]

# Attachment URLs
if {[calendar::attachments_enabled_p]} {
    set attachment_options "<A href=\"[attachments::add_attachment_url -object_id $cal_item(cal_item_id) -pretty_name $cal_item(name) -return_url "../cal-item-view?cal_item_id=$cal_item(cal_item_id)"]\" class=\"button\" >add attachment</a>"
} else { 
    set attachment_options {} 
}

set date $cal_item(start_date)
set show_synch_p [parameter::get -package_id $package_id -parameter ShowSynchP -default 1]
set cal_item(description) [ad_html_text_convert -from text/enhanced -to text/html -- $cal_item(description)]

# actions URLs
set goto_date_url [export_vars -base "./view" {{view day} {date $cal_item(start_date)}}]
set cal_item_new_url [export_vars -base "cal-item-new" {cal_item_id return_url}]
set cal_item_delete_url [export_vars -base "cal-item-delete" {cal_item_id return_url}]

# Header stuff
template::head::add_css -href "/resources/calendar/calendar.css" -media all
template::head::add_css -alternate -href "/resources/calendar/calendar-hc.css" -title "highContrast"

ad_return_template 

