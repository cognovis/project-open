ad_page_contract {
    spam confirmation page : displays spam body in plain text and HTML
    and prompts for confirmation 
} { 
    object_id
    sql_query
    {body_plain:trim ""}
    {body_html:allhtml,trim ""}
    subject:notnull
    send_date:array,date
    send_time:array,time
    num_recipients
    spam_id:naturalnum
    {confirm_target "spam-send"}
} 

# --------------------------------------------------
# Default & Security
# --------------------------------------------------

set user_id [ad_get_user_id]
set context [list "confirm"]

if {$body_plain == "" && $body_html == ""} { 
    ad_return_complaint 1 "You must supply either a text or HTML body, or both"
    return
} 

# --------------------------------------------------
# Put variables together
# --------------------------------------------------

set object_name [db_string object_name_for_one_object_id "select acs_object.name(:object_id) from dual" -default ""]
set object_type [db_string object_type "select object_type from acs_objects where object_id = :object_id"]
set object_rel_url [db_string object_url "select url from im_biz_object_urls where url_type = 'view' and object_type = :object_type"]
append object_rel_url $object_id

set spam_show_users_url "spam-show-users?[export_url_vars object_id sql_query]"

set spam_sender [db_string spam_sender "select first_names||' '||last_name||' <'||email||'>' from cc_users where user_id=:user_id"]

set send_date_ansi $send_date(date)
set pretty_date [util_AnsiDatetoPrettyDate $send_date_ansi]
set send_time_12hr "$send_time(time) $send_time(ampm)"

set export_vars [export_form_vars send_date_ansi send_time_12hr subject body_plain body_html spam_id sql_query object_id]

# --------------------------------------------------
# Format the sample text by substituting variables
# --------------------------------------------------

db_foreach spam_full_sql "" {

    set body_plain_subst [subst $body_plain]
    set body_html_subst [subst $body_html]
    set subject_subst [subst $subject]

    # Only do this for the first user in the list
    break
}

set escaped_body_plain_subst [ad_convert_to_html $body_plain_subst]

