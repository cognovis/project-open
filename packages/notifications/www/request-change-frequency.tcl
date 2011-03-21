ad_page_contract {

    Request a new notification - Ask for more stuff

    @author Tracy Adams (teadams@alum.mit.edu))
    @creation-date 2002-09-03
    @cvs-id $Id: request-change-frequency.tcl,v 1.3 2009/09/13 23:54:42 donb Exp $
} {
    request_id:integer,notnull
    return_url
}

set user_id [ad_conn user_id]

# get the notification information

db_1row select_notification_request {}

set doc(title) [_ notifications.Change_frequency]
set context [list $doc(title)]

set intervals [notification::get_intervals -localized -type_id $type_id]

ad_form -name change_frequency -export {request_id return_url} -form {
    {interval_id:integer(select)   
        {label "[_ notifications.Frequency]"}
        {options $intervals}
        {value $interval_id}}
} -on_submit {

    db_dml update_notification_frequency {}

    ad_returnredirect $return_url
    ad_script_abort

}

ad_return_template
