<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="intranet_mail_import::im_mail_import_new_message">
        <querytext>

         select im_mail_import_new_message (
		:cr_item_id,	-- cr_item_id
                null,           -- reply_to
                null,           -- sent_date
                null,           -- sender
                :rfc822_id,     -- rfc822_id
                :subject,       -- title
                :html,          -- html_text
                :plain,         -- plain_text
                :context_id,    -- context_id
                now(),          -- creation_date
                :user_id,       -- creation_user
                :peeraddr,      -- creation_ip
                'im_mail_message', -- object_type
                :approved_p,    -- approved_p
	 	:send_date, 	--send_date
		:header_from,	-- header_from
		:header_to	-- header_to
         );

        </querytext>
    </fullquery>


    <fullquery name="intranet_mail_import::im_mail_import_new_rel">
        <querytext>

        select acs_rel__new (
               	null,		-- rel_id
                :rel_type,	-- rel_type
                :object_id_one,
                :object_id_two,
		null,		-- context_id
                :creation_user,
                :creation_ip
        );

        </querytext>
    </fullquery>

</queryset>
