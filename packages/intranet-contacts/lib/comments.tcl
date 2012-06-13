#    @author Matthew Geddert openacs@geddert.com
#    @creation-date 2005-05-09
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




set total_count [db_string get_count {
        select count(*)
               from general_comments g,
               cr_revisions r,
               acs_objects o
         where g.object_id = :party_id
           and r.revision_id = content_item__get_live_revision(g.comment_id)
           and o.object_id = g.comment_id
}]




if { [exists_and_not_null limit] } {
    set limit_clause "limit $limit"
} else {
    set limit_clause ""
}




set result_number 1

db_multirow -extend { comment_html comment_number contact_url } comments get_comments "
         select g.comment_id,
                r.title,
                r.mime_type,
                o.creation_user,
                acs_object__name(o.creation_user) as author,
                CASE WHEN to_char(o.creation_date, 'YYYY') = to_char(now(),'YYYY') THEN to_char(o.creation_date,'Mon FMDD') ELSE to_char(o.creation_date,'Mon FMDD, YYYY') END as pretty_date,
                to_char(o.creation_date, 'FMHH12:MIpm') as pretty_time,
                content
           from general_comments g,
                cr_revisions r,
                acs_objects o
          where g.object_id = :party_id
            and r.revision_id = content_item__get_live_revision(g.comment_id)
            and o.object_id = g.comment_id
          order by $orderby_clause
          $limit_clause
" {
    if { [exists_and_not_null truncate_len] } {
        set comment_html [ad_html_text_convert -truncate_len $truncate_len -from $mime_type -to "text/html" $content]
    } else {
        set comment_html [ad_html_text_convert -from $mime_type -to "text/html" $content]
    }
    if { $recent_on_top_p } {
        set comment_number [expr $total_count - $result_number + 1]
    } else {
        set comment_number $result_number
    }
    incr result_number
    set contact_url [contact::url -party_id $creation_user]
}

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

set user_id [ad_conn user_id]
