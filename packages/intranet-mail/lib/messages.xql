<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="select_messages">
        <querytext>
         select 
		message_id, 
		sender_id, 
		from_addr,
		package_id, 
		sent_date, 
		body, 
		subject, 
		context_id,
	        to_addr,
		log_id
        from 
		acs_mail_log
	where   [template::list::page_where_clause -name messages]		
        	[template::list::filter_where_clauses -and -name messages]
        	[template::list::orderby_clause -orderby -name messages]
        </querytext>
    </fullquery>

    <fullquery name="messages_pagination">
        <querytext>
        select distinct ml.log_id, ml.sent_date, ml.sender_id, ml.package_id, ml.subject
        from acs_mail_log ml left outer join acs_mail_log_recipient_map mlrm on (ml.log_id=mlrm.log_id)
	where ml.log_id is not null
	$recipient_where_clause 
        [template::list::filter_where_clauses -and -name messages]
        [template::list::orderby_clause -orderby -name messages]
        </querytext>
    </fullquery>

    <fullquery name="files">
        <querytext>
	select cr.title, cr.revision_id as version_id from acs_mail_log_attachment_map lam, cr_revisions cr
	where log_id = :log_id
    and cr.revision_id = lam.file_id
        </querytext>
    </fullquery>

</queryset>
