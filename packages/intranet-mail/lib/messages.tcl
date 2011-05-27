# packages/intranet-mail/lib/messages.tcl

## Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
# 
# Expects the following optional parameters (in each combination):
#
# recipient        - to filter mails for a single recipient (which can
# be both a company or a person)
# sender           - to filter mails for a single sender
# object           - to filter mails for a object_id
# party            - filter for the recipient, which is actually a sender or recipient
# page             - to filter the pagination
# page_size        - to know how many rows show (optional default to 10)
# show_filter_p    - to show or not the filters in the inlcude, default to "t"
# elements         - a list of elements to show in the list template. If not provided will show all elements.
#                    Posible elemets are: sender recipient subject object file_ids body sent_date

ad_page_contract {

    @author Nima Mazloumi
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
} -query {
    recipient:optional
    party:optional
    {emp_mail_f:optional 1}
    sender:optional
    object:optional
    {messages_orderby:optional "sent_date,desc"}
} -properties {
    show_filter_p
    acs_mail_log:multirow 
    context:onevalue
}

set show_filter_p 0
set page_title [ad_conn instance_name]
set context [list "index"]

#Only to make the code more legible
if {[info exists object]} {
    set project $object
}

set required_param_list [list]
set optional_param_list [list party pass_through_vars]
set optional_unset_list [list pkg_id project recipient sender page]

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

if { ![exists_and_not_null show_filter_p] } {
    set show_filter_p "t"
}

if { ![exists_and_not_null page_size] } {
    set page_size 5
}


set tracking_url [apm_package_url_from_key "intranet-mail"]
# Wich elements will be shown on the list template
set rows_list [list]
if {![exists_and_not_null elements] } {
    set rows_list [list status {} sender {} recipient {} subject {} project {} file_ids {} body {} sent_date {}]
} else {
    foreach element $elements {
	lappend rows_list $element
	lappend rows_list [list]
    }
}

set filters [list \
		 sender {
		     label "[_ intranet-mail.Sender]"
		     where_clause "sender_id = :sender"
		 } \
		 project {
		     label "[_ intranet-mail.Context_id]"
		     where_clause "context_id = :project"
		 } 
	    ]

foreach pass_through_var $pass_through_vars {
    lappend filters $pass_through_var {}
}

# If we query for an organization (company)
if { [apm_package_installed_p contacts] && [exists_and_not_null recipient]} {
    set org_p [organization::organization_p -party_id $recipient] 
    if { $org_p } {
	lappend filters emp_mail_f {
	    label "[_ intranet-mail.Emails_to]"
	    values { {"[_ intranet-mail.Organization]" 1} { "[_ intranet-mail.Employees]" 2 }}
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

template::list::create \
    -name messages \
    -selected_format normal \
    -multirow messages \
    -key acs_mail_log.log_id \
    -orderby_name "messages_orderby" \
    -page_size $page_size \
    -page_flush_p 1 \
    -page_query_name "messages_pagination" \
    -row_pretty_plural "[_ intranet-mail.messages]" \
    -elements { 
	sender {
	    label "[_ intranet-mail.Sender]"
	    display_template {
		@messages.sender_name;noquote@
	    }
	}
	recipient {
	    label "[_ intranet-mail.Recipient]"
	    display_template {
		@messages.recipient;noquote@
	    }
	}
	subject {
	    label "[_ intranet-mail.Subject]"
	}
	project {
	    label "[_ intranet-mail.Context_id]"
	    display_template {
		<a href="@messages.context_url@">@messages.context_id@</a>
	    }
	}
	file_ids {
	    label "[_ intranet-mail.Files]"
	    display_template {@messages.download_files;noquote@}
	}
	body {
	    label "[_ intranet-mail.Body]"
	    display_template {
            <a href="@messages.message_url;noquote@" title="#intranet-mail.View_full_message#">#intranet-mail.View#</a>
	    }
	}
	sent_date {
	    label "[_ intranet-mail.Sent_Date]"
	}            
	status {
	    label "[_ intranet-mail.Status]"
	}
    } -orderby {
	sender {
	    orderby sender_id
	    label "[_ intranet-mail.Sender]"
	}
	subject {
	    orderby subject
	    label "[_ intranet-mail.Subject]"
	}
	sent_date {
	    orderby sent_date
	    label "[_ intranet-mail.Sent_Date]"
	} 
    } -formats {
        normal {
            label "Table"
            layout table
            row $rows_list
        }
    } -filters $filters \

db_multirow -extend { status file_ids context_url sender_name message_url recipient package_name package_url url_message_id download_files} messages select_messages { } {

    if {[views::viewed_p -object_id $log_id]} {
        set status ""
    } else {
        set status "NEW"
    }

    if {[exists_and_not_null sender_id]} { 
        set sender_name "[party::name -party_id $sender_id]"
    } else {
        set sender_name $from_addr
    }
    
    set message_url [export_vars -base "${tracking_url}one-message" -url {log_id return_url}]
    set reciever_list $to_addr
    set reciever_list2 [db_list get_recievers {select recipient_id from acs_mail_log_recipient_map where type ='to' and log_id = :log_id and recipient_id is not null}] 
    
    foreach recipient_id $reciever_list2 {
        lappend reciever_list "[party::name -party_id $recipient_id]</a>"
    }

    set recipient [join $reciever_list "<br>"]
    
    set package_name ""
    set package_url ""

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
    
    db_foreach files {} {
        append download_files "<a href=\"[export_vars -base "${tracking_url}download/$title" -url {version_id}]\">$title</a><br>"
    }

    set context_url "/o/$context_id"
}

if {[exists_and_not_null object]} {
    set mail_url [export_vars -base "${tracking_url}mail" -url {{object_id $project} return_url}]
} else {
    set mail_url ""
}
ad_return_template