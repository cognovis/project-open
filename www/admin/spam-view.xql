<?xml version="1.0"?>
<queryset>


<fullquery name="spam_get_multipart_plain_text">
        <querytext>

        select cr.content as plain_text
        from acs_mail_multipart_parts mpp 
        join cr_items ci on mpp.content_item_id=ci.item_id
        join cr_revisions cr on ci.live_revision=cr.revision_id
        where multipart_id=:content_item_id and cr.mime_type='text/plain'; 

        </querytext>
</fullquery>

 
<fullquery name="spam_get_multipart_html_text">
        <querytext>

        select cr.content as html_text
        from acs_mail_multipart_parts mpp 
        join cr_items ci on mpp.content_item_id=ci.item_id
        join cr_revisions cr on ci.live_revision=cr.revision_id
        where multipart_id=:content_item_id and cr.mime_type='text/html'; 

        </querytext>
</fullquery>

 
</queryset>
