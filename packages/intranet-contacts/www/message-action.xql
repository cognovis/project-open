<?xml version="1.0"?>
<queryset>

<fullquery name="select_message_info">
      <querytext>
      select title,
             acs_object_id_seq.nextval as new_item_id,
             owner_id as old_owner_id,
             message_type,
             title,
             description,
             content,
             content_format
        from contact_messages
       where item_id = :item_id
      </querytext>
</fullquery>

<fullquery name="update_owner">
      <querytext>
      update contact_message_items
         set owner_id = :owner_id
       where item_id = :item_id
      </querytext>
</fullquery>

<fullquery name="select_similar_titles">
      <querytext>
      select title
        from contact_messages
       where owner_id = :owner_id
         and upper(title) like upper('${sql_title}%')
      </querytext>
</fullquery>

<fullquery name="expire_message">
      <querytext>
      update cr_items
         set publish_status = 'expired'
       where item_id = :item_id
      </querytext>
</fullquery>


</queryset>
