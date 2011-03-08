<?xml version="1.0"?>
<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="attachments::get_attachments.select_attachments">
        <querytext>
            select item_id
            from attachments
            where object_id = :object_id
            and approved_p = 't'
        </querytext>
    </fullquery>
 
    <fullquery name="attachments::get_all_attachments.select_attachments">
        <querytext>
            select item_id,
                   approved_p
            from attachments
            where object_id = :object_id
        </querytext>
    </fullquery>
 
</queryset>
