#    @author Matthew Geddert openacs@geddert.com
#    @creation-date 2005-07-09
#    @cvs-id $Id$

if { [string is false [contact::exists_p -party_id $party_id]] } {
    error "[_ intranet-contacts.lt_The_party_id_specifie]"
}

if { [string is false [exists_and_not_null recent_on_top_p]] } {
    set recent_on_top_p [parameter::get_from_package_key -boolean -package_key "general-comments" -parameter "RecentOnTopP"]
}

if { [string is false [exists_and_not_null recent_on_top_p]] } {
    error "[_ intranet-contacts.lt_The_parameter_RecentO]"
} else {
    if { $recent_on_top_p } {
        set orderby_clause "creation_date desc"
    } else {
        set orderby_clause "creation_date asc"
    }
}
if { [string is false [exists_and_not_null size]] } {
    set size "normal"
}
switch $size {
    normal  {
        set textarea_size "cols 50 rows 6"
    }
    small   {
        set textarea_size "cols 35 rows 3"
    }
    default { error "[_ intranet-contacts.lt_You_have_specified_an_1]" }
}

if { [string is false [exists_and_not_null form]] } {
    if { $recent_on_top_p } {
        set form "top"
    } else {
        set form "bottom"
    }
}
if { [lsearch [list top bottom none] $form] < 0 } {
    error "[_ intranet-contacts.lt_Invalid_input_you_spe]"
}

if { ![exists_and_not_null hide_form_p] } {
    set hide_form_p 0
}

if { [string is false $hide_form_p] } {
ad_form -name comment_add \
   -action "[ad_conn package_url]comment-add" \
    -form "
        party_id:integer(hidden)
        return_url:text(hidden),optional
        {comment:text(textarea),nospell {label {}} {html {$textarea_size}} {after_html {<br />}}}
        {save:text(submit),optional {label {[_ intranet-contacts.Add_Comment]}}}
    " -on_request {
    } -after_submit {
    }
}
set user_id [ad_conn user_id]


if { ![exists_and_not_null truncate_len] } {
    set truncate_len ""
}

template::multirow create hist timestamp object_id creation_user content include
callback contact::history -party_id $party_id -multirow "hist" -truncate_len $truncate_len


db_foreach get_comments "
         select g.comment_id,
                o.creation_user,
                o.creation_date,
                content,
                r.title,
                r.mime_type
           from general_comments g,
                cr_revisions r,
                acs_objects o
          where g.object_id = :party_id
            and r.revision_id = content_item__get_live_revision(g.comment_id)
            and o.object_id = g.comment_id
" {
    if { [exists_and_not_null truncate_len] } {
        set comment_html [ad_html_text_convert -truncate_len $truncate_len -from $mime_type -to "text/html" $content]
    } else {
        set comment_html [ad_html_text_convert -from $mime_type -to "text/html" $content]
    }
    template::multirow append "hist" $creation_date $comment_id $creation_user $comment_html ""
}


db_foreach get_messages "
         select message_id,
                message_type,
                sender_id,
                sent_date,
                title,
                description,
                content,
                content_format
           from contact_message_log
          where recipient_id = :party_id
            and content not like ('%Manage your notifications at: http:%')
" {

    set message_url [export_vars -base "[ad_conn package_url]message-log" -url {message_id}]

    set header "<em><a href=\"${message_url}\">[_ intranet-contacts.$message_type] [_ intranet-contacts.Message]</a>:</em> "
    if { [exists_and_not_null title] } {
	set content_html "$header<a href=\"$message_url\">$title</a>"
    } else {
	set content [ad_html_text_convert \
			      -from $content_format \
			      -to "text/plain" \
			      -- $content]
	regsub -all "\r|\n" $content {LiNeBrEaK} content

	set content_html [ad_html_text_convert \
			      -from text/plain \
			      -to "text/html" \
			      -truncate_len "600" \
			      -more "<a href=\"${message_url}\">[_ intranet-contacts.more]</a>" \
			      -- $content]
	regsub -all {LiNeBrEaKLiNeBrEaK} $content_html {LiNeBrEaK} content_html
	#    regsub -all {LiNeBrEaKLiNeBrEaK} $content_html {LiNeBrEaK} content_html
	#    regsub -all {LiNeBrEaKLiNeBrEaK} $content_html {LiNeBrEaK} content_html 
	# 167 is the actual paragraph standard internationally but 182 is more common in the US
	regsub -all {LiNeBrEaK} $content_html {\&nbsp;\&nbsp;\&#182;\&nbsp;} content_html
	    set content_html "${header}${content_html}"
    }
    template::multirow append "hist" $sent_date $message_id $sender_id $content_html ""
}


template::multirow sort hist -decreasing timestamp
template::multirow create history date time object_id creation_user user_link include content delete_url

set deleted_history [db_list select_deleted_history {}]
set return_url [string trimright "[ad_conn url]?[ad_conn query]" "?"]

if { [permission::permission_p -party_id $user_id -object_id [ad_conn package_id] -privilege admin] } {
    set delete_permission "all"
} else {
    set delete_permission [string tolower [parameter::get -parameter "DeleteHistoryPermission" -default "no"]]
}


set result_number 1
template::multirow foreach hist {
    if { [lsearch $deleted_history $object_id] < 0 } {
	set timestamp     [lindex [split $timestamp "."] 0]
	set date          [lc_time_fmt $timestamp "%q"]
	set time          [string trimleft [lc_time_fmt $timestamp "%X"] "0"]
	#    set object_id     
	#    set creation_user 
	set user_link     [contact::name -party_id $creation_user]
	#    set content
	#    set include
	if { [lsearch [list yours all] $delete_permission] < 0 } {
	    set delete_url ""
	} else {
	    set delete_url [export_vars -base "[contact::url -party_id $party_id]history" -url {{delete_object_id $object_id} return_url}]
	    if { $delete_permission eq "yours" } {
		# we need to verify that they have permission to delete
                # this object form history
		acs_object::get -object_id $object_id -array acs_object
		if { $user_id ne $acs_object(creation_user) } {
		    # they do not have permission to delete this object from history
		    set delete_url ""
		}
	    }
	}

	template::multirow append history $date $time $object_id $creation_user $user_link $include $content $delete_url
	if { [exists_and_not_null limit] } {
	    incr result_number
	    if { $result_number > $limit } {
		break
	    }
	}
    }
}







