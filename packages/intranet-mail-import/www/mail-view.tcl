ad_page_contract {
    view a given piece of spam
} {
    body_id:integer
}

set title ""
set context [list]

set field_list [acs_mail_body_to_output_format -body_id $body_id]

set to [lindex $field_list 0]
set from [lindex $field_list 1]
set subject [lindex $field_list 2]
set body [lindex $field_list 3]
set extraheaders [lindex $field_list 4]

set send_date [db_string sent "select to_char(creation_date, 'YYYY-MM-DD HH24:MI:SS') from acs_objects where object_id=:body_id" -default ""]

