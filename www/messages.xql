<?xml version="1.0"?>
<queryset>

<fullquery name="select_owner_options">
      <querytext>
      select CASE WHEN owner_id = :user_id
                  THEN '\#contacts.My_Messages\#'
                  ELSE contact__name(owner_id) END,
             owner_id
        from ( select distinct owner_id
                 from contact_messages
                where package_id = :package_id
                  and ( contact_messages.title is not null or owner_id = :user_id )
                  and owner_id in ( select party_id from parties )) distinct_owners
        order by CASE WHEN owner_id = :user_id THEN '0000000000000000000' ELSE upper(contact__name(owner_id)) END
      </querytext>
</fullquery>

<fullquery name="select_messages">
      <querytext>
    select item_id,
           owner_id,
           message_type,
           title,
           description,
           content,
           content_format,
	   locale
      from contact_messages
     where owner_id = :owner_id
       and package_id = :package_id
     order by message_type, upper(title)
      </querytext>
</fullquery>

</queryset>
