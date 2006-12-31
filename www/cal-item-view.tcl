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

set write_p [permission::write_permission_p -object_id $cal_item_id -creation_user $cal_item(creation_user)]

# Direct redirect
if {"t" == $cal_item(redirect_to_rel_link_p)} { ad_returnredirect $cal_item(related_link_url) }


if {[exists_and_not_null return_url]} {
    set return_url [ad_urlencode $return_url]
}

# Attachments?
if {$cal_item(n_attachments) > 0} {
    set item_attachments [attachments::get_attachments -object_id $cal_item(cal_item_id) -return_url [ad_return_url]]
} else {
    set item_attachments [list]
}

# no time?
set cal_item(no_time_p) [dt_no_time_p -start_time $cal_item(start_time) -end_time $cal_item(end_time)]

# Attachment URLs
if {[calendar::attachments_enabled_p]} {
    set attachment_options "\[<A href=\"[attachments::add_attachment_url -object_id $cal_item(cal_item_id) -pretty_name $cal_item(name) -return_url "../cal-item-view?cal_item_id=$cal_item(cal_item_id)"]\" class=\"button\" >add attachment</a>\]"
} else { 
    set attachment_options {} 
}

set date $cal_item(start_date)
set show_synch_p [parameter::get -package_id $package_id -parameter ShowSynchP -default 1]
set cal_item(description) [ad_html_text_convert -from text/enhanced -to text/html $cal_item(description)]

ad_return_template 

