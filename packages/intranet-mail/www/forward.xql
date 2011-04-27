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
	select file_id from acs_mail_log_attachment_map
	where log_id = :log_id
        </querytext>
    </fullquery>

</queryset>