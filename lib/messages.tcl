# Expects the following optional parameters (in each combination):
#
# recipient        - to filter mails for a single receiver
# sender           - to filter mails for a single sender
# object_id        - to filter mails for a object_id
# party    - filter for the recipient, which is actually a sender or recipient
# page             - to filter the pagination
# page_size        - to know how many rows show (optional default to 10)
# show_filter_p    - to show or not the filters in the inlcude, default to "t"
# from_package_id  - to watch mails of this package instance  
# elements         - a list of elements to show in the list template. If not provided will show all elements.
#                    Posible elemets are: sender recipient pkg_id subject object file_ids body sent_date

ad_page_contract {

    @author Nima Mazloumi
    @creation-date Mon May 30 17:55:50 CEST 2005
    @cvs-id $Id$
} -query {
    recipient_id:optional
    sender_id:optional
    recipient:optional
    party:optional
    {emp_mail_f:optional 1}
    sender:optional
    from_package_id:optional
    object_id:optional
    object:optional
    {orderby:optional "sent_date,desc"}
} -properties {
    show_filter_p
    acs_mail_log:multirow 
    context:onevalue
}

set page_title [ad_conn instance_name]
set context [list "index"]

set required_param_list [list]
set optional_param_list [list from_package_id recipient_id object_id party]
set optional_unset_list [list pkg_id object recipient sender]

foreach required_param $required_param_list {
    if {![info exists $required_param]} {
        return -code error "$required_param is a required parameter."
    }
}

foreach optional_param $optional_param_list {
    if {![info exists $optional_param]} {
        set $optional_param {}
    }
}

foreach optional_unset $optional_unset_list {
    if {[info exists $optional_unset]} {
        if {[empty_string_p [set $optional_unset]]} {
            unset $optional_unset
        }
    }
}

set package_id_list [list]
if { [exists_and_not_null sender_id] } {
    set sender $sender_id
}

if { [exists_and_not_null recipient_id] } {
    set recipient $recipient_id
    set package_id_list [concat $package_id_list [db_list package_ids "select package_id from acs_mail_log where recipient_id = :sender"]]
}

if { [exists_and_not_null object_id] } {
    set object $object_id
} 

if { [exists_and_not_null from_package_id] } {
    set pkg_id $from_package_id
}

if { ![exists_and_not_null show_filter_p] } {
    set show_filter_p "t"
}

if { ![exists_and_not_null page_size] } {
    set page_size 5
}

set tracking_url [apm_package_url_from_key "mail-tracking"]
# Wich elements will be shown on the list template
set rows_list [list]
if {![exists_and_not_null elements] } {
    set rows_list [list sender {} recipient {} pkg_id {} subject {} object {} file_ids {} body {} sent_date {}]
} else {
    foreach element $elements {
	lappend rows_list $element
	lappend rows_list [list]
    }
}

set filters [list \
		 sender {
		     label "[_ mail-tracking.Sender]"
		     where_clause "sender_id = :sender"
		 } \
		 object {
		     label "[_ mail-tracking.Object_id]"
		     where_clause "object_id = :object"
		 } 
	    ]

if { [apm_package_installed_p contacts] && [exists_and_not_null recipient]} {
    set org_p [organization::organization_p -party_id $recipient] 
    if { $org_p } {
	lappend filters emp_mail_f {
	    label "[_ mail-tracking.Emails_to]"
	    values { {"[_ mail-tracking.Organization]" 1} { "[_ mail-tracking.Employees]" 2 }}
	}
    }
    
    if { $org_p && [string equal $emp_mail_f 2] } {
	set emp_list [contact::util::get_employees -organization_id $recipient]
	lappend emp_list $recipient
	set recipient_where_clause " and mlrm.recipient_id in ([template::util::tcl_to_sql_list $emp_list])"
    } else {
	set recipient_where_clause " and mlrm.recipient_id = :recipient"
    }
} elseif { [exists_and_not_null recipient] }  {
    set recipient_where_clause " and mlrm.recipient_id = :recipient"
} elseif { [exists_and_not_null party]} {
    set recipient_where_clause " and (mlrm.recipient_id = :party or sender_id = :party)"
} else {
    set recipient_where_clause ""
}

# If we have a recipient filter, offer the filter for package_ids
set package_id_list [list]
if {$recipient_where_clause ne ""} {
    set package_ids [db_list package_ids "select distinct package_id as package_id2 from acs_mail_log ml, acs_mail_log_recipient_map mlrm where ml.log_id = mlrm.log_id $recipient_where_clause"]
    foreach package_id2 $package_ids {
	lappend package_id_list [list [acs_object_name $package_id2] $package_id2]
    }    
}

# Always append the filter for package_ids, but note that it is only selectable if we filter by recipient
lappend filters pkg_id {
    label "[_ mail-tracking.Package]"
    values $package_id_list
    where_clause "package_id = :pkg_id"	
} 

template::list::create \
    -name messages \
    -selected_format normal \
    -multirow messages \
    -key acs_mail_log.log_id \
    -page_size $page_size \
    -page_flush_p 1 \
    -page_query_name "messages_pagination" \
    -row_pretty_plural "[_ mail-tracking.messages]" \
    -elements { 
	sender {
	    label "[_ mail-tracking.Sender]"
	    display_template {
		@messages.sender_name;noquote@
	    }
	}
	recipient {
	    label "[_ mail-tracking.Recipient]"
	    display_template {
		@messages.recipient;noquote@
	    }
	}
	pkg_id {
	    label "[_ mail-tracking.Package]"
	    display_template {
		<a href="@messages.package_url@">@messages.package_name@</a>
	    }
	}
	subject {
	    label "[_ mail-tracking.Subject]"
	}
	object {
	    label "[_ mail-tracking.Object_id]"
	    display_template {
		<a href="@messages.object_url@">@messages.object_id@</a>
	    }
	}
	file_ids {
	    label "[_ mail-tracking.Files]"
	    display_template {@messages.download_files;noquote@}
	}
	body {
	    label "[_ mail-tracking.Body]"
	    display_template {
		<a href="${tracking_url}one-message?log_id=@messages.log_id@" title="#mail-tracking.View_full_message#">#mail-tracking.View#</a>
	    }
	}
	sent_date {
	    label "[_ mail-tracking.Sent_Date]"
	}            
    } -orderby {
	sender {
	    orderby sender_id
	    label "[_ mail-tracking.Sender]"
	}
	pkg_id {
	    orderby package_id
	    label "[_ mail-tracking.Package]"
	}
	subject {
	    orderby subject
	    label "[_ mail-tracking.Subject]"
	}
	sent_date {
	    orderby sent_date
	    label "[_ mail-tracking.Sent_Date]"
	}
    } -formats {
	normal {
	    label "Table"
	    layout table
	    row $rows_list
	}
    } -filters $filters \


db_multirow -extend { file_ids object_url sender_name recipient package_name package_url url_message_id download_files} messages select_messages { } {

    if {[exists_and_not_null sender_id]} { 
	if { [apm_package_installed_p contacts] } {
	    set sender_name "<a href=\"[contact::url -party_id $sender_id -package_id [contact::package_id -party_id $sender_id]]\">[party::name -party_id $sender_id]</a>"
	} else {
	    set sender_name "[party::name -party_id $sender_id]"
	}
    } else {
	set sender_name $from_addr
    }
    
    set reciever_list [list]
    set reciever_list2 [db_list get_recievers {select recipient_id from acs_mail_log_recipient_map where type ='to' and log_id = :log_id and recipient_id is not null}] 
    
    foreach recipient_id $reciever_list2 {
	if { [apm_package_installed_p contacts] } { 
	    lappend reciever_list "<a href=\"[contact::url -party_id $recipient_id -package_id [contact::package_id -party_id $recipient_id]]\">[party::name -party_id $recipient_id]</a>"
	} else {
	    lappend reciever_list "[party::name -party_id $recipient_id]</a>"
	}
    }

    set recipient [join $reciever_list "<br>"]
    
    if {[exists_and_not_null package_id]} {
	set package_name [apm_instance_name_from_id $package_id]
	set package_url [apm_package_url_from_id $package_id]
    } else {
	set package_name ""
	set package_url ""
    }


    set count 0
    while {[regexp {^(.*?)\t?=\?[^\?]+\?Q\?(.*?)\?=\n?(.*?)$} $subject match before quoted after] && $count < 5} {
	incr count
	set result ""
	for { set i 0 } { $i < [string length $quoted] } { incr i } {
	    set current [string index $quoted $i]
	    if {$current == "="} {
		incr i
		set high [string index $quoted $i]
		incr i
		set low [string index $quoted $i]
		set current [binary format H2 "$high$low"]
	    } elseif {[string eq $current "_"]} {
		set current " "
	    }
	    append result $current
	}
	set subject "$before$result$after"
    }

    set files [db_list files {}]
    foreach file_id $files {
	set title [content::item::get_title -item_id $file_id]
	append download_files "<a href=\"[export_vars -base "${tracking_url}download/$title" -url {file_id}]\">$title</a><br>"
    }

    set object_url "/o/$object_id"
}


 
ad_return_template