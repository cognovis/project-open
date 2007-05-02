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

    if {[catch {
	calendar::new \
	    -owner_id [ad_conn user_id] \
	    -calendar_name $calendar_name 
    } errmsg]} {
	ad_return_complaint 1 "
		<b>[lang::message::lookup "" calendar.Duplicate_Calendar_Name "Duplicate Calendar Name:"]</b><p>
		[lang::message::lookup "" calendar.Duplicate_Calendar_Name_Message "
			A calendar with name '%calendar_name%' already exists.<br>
			Please choose a different name.<p>
			Here is the error message for reference:<p>
			<pre>%errmsg%</pre>
		"]
	"
    }

} -edit_data {
    calendar::rename \
        -calendar_id $calendar_id \
        -calendar_name $calendar_name 
} -after_submit {
    ad_returnredirect .
    ad_script_abort
}


