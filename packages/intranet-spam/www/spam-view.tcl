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

ad_return_template
return




if [acs_mail_multipart_p $content_item_id] {

    db_1row spam_get_multipart_plain_text "
	select 
		content 
	from 
		acs_mail_multipart_parts, 
		acs_contents
	where
		multipart_id = :content_object_id
	       	and content_id = content_object_id
  	       	and mime_type = 'text/plain'
	"
    db_1row spam_get_multipart_html_text "
	    select content 
	    from acs_mail_multipart_parts, acs_contents
	    where multipart_id = :content_object_id
	       and content_id = content_object_id
  	       and mime_type = 'text/plain'
	"


} else {
    db_1row spam_get_text {
	select content, mime_type
	  from acs_contents
	where content_id = :content_object_id
    }
    if {$mime_type == "text/plain"} {
	set plain_text $content
    } elseif {$mime_type == "text/html"} {
	set html_text $content
    } else {
	ad_return_error "invalid content type in spam: $mime_type"
    }
}     

