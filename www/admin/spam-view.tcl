ad_page_contract {
    view a given piece of spam
} {
    spam_id:integer,notnull
}

db_1row spam_get_message {
    select header_subject as title, 
           to_char(send_date, 'Month DD, YYYY HH:MI:SS') as send_date,
           content_item_id 
     from spam_messages_all
     where spam_id = :spam_id
}

set html_text ""
set plain_text ""

if [acs_mail_multipart_p $content_item_id] {

    db_1row spam_get_multipart_plain_text "
        select cr.content as plain_text
        from acs_mail_multipart_parts mpp 
        join cr_items ci on mpp.content_item_id=ci.item_id
        join cr_revisions cr on ci.live_revision=cr.revision_id
        where multipart_id=:content_item_id and cr.mime_type='text/plain'; 
	"
    db_1row spam_get_multipart_html_text "
        select cr.content as html_text
        from acs_mail_multipart_parts mpp 
        join cr_items ci on mpp.content_item_id=ci.item_id
        join cr_revisions cr on ci.live_revision=cr.revision_id
        where multipart_id=:content_item_id and cr.mime_type='text/html'; 
	"
	

} else {
    db_1row spam_get_text {
	select content, mime_type
	  from cr_revisions
	where revision_id = content_item__get_live_revision(:content_item_id)
    }
    if {$mime_type == "text/plain"} {
	set plain_text $content
    } elseif {$mime_type == "text/html"} {
	set html_text $content
    } else {
	ad_return_error "invalid content type in spam: $mime_type"
    }
}     

set context [list]

ad_return_template
