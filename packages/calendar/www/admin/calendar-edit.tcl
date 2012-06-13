ad_page_contract {
    
    Add/Edit calendar

    @creation-date Dec 14, 2000
    @cvs-id $Id$
} {
    {calendar_id:integer,optional}
}

set page_title "Add/Edit Calendar"
set context [list $page_title]

ad_form -name calendar -form {
    {calendar_id:key}
    {calendar_name:text
        {label "[_ calendar.Calendar_Name]"}
        {html {size 50}}
    }
} -edit_request {
    set calendar_name [calendar::name $calendar_id]
} -new_data {
    calendar::new \
        -owner_id [ad_conn user_id] \
        -calendar_name $calendar_name 
} -edit_data {
    calendar::rename \
        -calendar_id $calendar_id \
        -calendar_name $calendar_name 
} -after_submit {
    ad_returnredirect .
    ad_script_abort
}


