<? xml version="1.0"?>
<queryset>

<fullquery name="message_exists_p">
    <querytext>
	select 
		1 
	from 
		acs_mail_log
	where 
		log_id = :log_id
    </querytext>
</fullquery>


<fullquery name="get_message_info">
    <querytext>
	select 
		*
	from 
		acs_mail_log
	where
		log_id = :log_id
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