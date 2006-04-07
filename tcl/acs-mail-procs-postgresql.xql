<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="acs_mail_set_content.insert_new_content">      
<querytext>

select content_item__new(
    'acs-mail message $body_id'::varchar, -- new__name
    null::integer,                     -- new__parent_id
    null::integer,                     -- new__item_id
    null::varchar,                     -- new__locale
    current_timestamp,                    -- new__creation_date
    :creation_user::integer,           -- new__creation_user
    null::integer,                     -- new__context_id
    :creation_ip::varchar,             -- new__creation_ip
    'content_item'::varchar,           -- new__item_subtype
    'content_revision'::varchar,       -- new__content_type
    :header_subject::varchar,          -- new__title
    null::varchar,                     -- new__description
    :content_type,            -- new__mime_type
    :nls_language,            -- new__nls_language
    :content,                 -- new__text
    'text'                    -- new__storage_type
  )
    
</querytext>
</fullquery>

 

<fullquery name="acs_mail_set_content.get_latest_revision">
<querytext>

begin
  return content_item__get_latest_revision ( :item_id );
end;

</querytext>
</fullquery>



<fullquery name="acs_mail_set_content.set_live_revision">
<querytext>

select content_item__set_live_revision(:revision_id);

</querytext>
</fullquery>



<fullquery name="acs_mail_set_content_file.insert_new_content">
<querytext>

begin
  return content_item__new(
    varchar 'acs-mail message $body_id', -- new__name
    null,                     -- new__parent_id
    null,                     -- new__item_id
    null,                     -- new__locale
    now(),                    -- new__creation_date
    :creation_user,           -- new__creation_user
    null,                     -- new__context_id
    :creation_ip,             -- new__creation_ip
    'content_item',           -- new__item_subtype
    'content_revision',       -- new__content_type
    :header_subject,          -- new__title
    null,                     -- new__description
    :content_type,            -- new__mime_type
    :nls_language,            -- new__nls_language
    null,                     -- new__text
    'file'                    -- new__storage_type
  );
end;

</querytext>
</fullquery>


<fullquery name="acs_mail_set_content_file.get_latest_revision">
<querytext>

begin
  return content_item__get_latest_revision ( :item_id );
end;

</querytext>
</fullquery>



<fullquery name="acs_mail_set_content_file.set_live_revision">
<querytext>

select content_item__set_live_revision(:revision_id)

</querytext>
</fullquery>



<fullquery name="acs_mail_set_content_file.update_content">
<querytext>

update cr_revisions
  set content = '[cr_create_content_file $item_id $revision_id $content_file]'
  where revision_id = :revision_id

</querytext>
</fullquery>


<fullquery name="acs_mail_encode_content.get_latest_revision">
<querytext>

begin
  return content_item__get_latest_revision ( :content_item_id );
end;

</querytext>
</fullquery>



<fullquery name="acs_mail_encode_content.copy_blob_to_file">
<querytext>
      
select r.lob as content, i.storage_type 
from cr_revisions r, cr_items i 
where r.revision_id = $revision_id and
      r.item_id = i.item_id
        
</querytext>
</fullquery>

<fullquery name="acs_mail_content_new.acs_mail_content_new">      
<querytext>

select acs_mail_gc_object__new (
  :object_id,			-- gc_object_id 
  'acs_mail_gc_object',		-- object_type
  now(),			-- creation_date
  :creation_user,		-- creation_user 
  :creation_ip,			-- creation_ip 
  null				-- context_id
);

</querytext>
</fullquery>

 
<fullquery name="acs_mail_body_new.acs_mail_body_new">      
<querytext>

select acs_mail_body__new (
  :body_id,			-- body_id 
  :body_reply_to,		-- body_reply_to 
  :body_from,			-- body_from 
  :body_date,			-- body_date 
  :header_message_id,		-- header_message_id 
  :header_reply_to,		-- header_reply_to 
  :header_subject,      	-- header_subject 
  :header_from,			-- header_from 
  :header_to,			-- header_to 
  :content_item_id,		-- content_item_id 
  'acs_mail_body',		-- object_type
  now() ::date,			-- creation_date
  :creation_user,		-- creation_user 
  :creation_ip,			-- creation_ip 
  null				-- context_id
);

</querytext>
</fullquery>



 
<fullquery name="acs_mail_body_p.acs_mail_body_p">      
<querytext>

select acs_mail_body__body_p (:object_id);

</querytext>
</fullquery>


 

<fullquery name="acs_mail_body_clone.acs_mail_body_clone">      
<querytext>

select acs_mail_body__clone (
  :old_body_id,		-- old_body_id 
  :body_id,			-- body_id 
  :creation_user,	-- creation_user 
  :creation_ip		-- creation_ip 
);

</querytext>
</fullquery>

 


<fullquery name="acs_mail_body_set_content_object.acs_mail_body_set_content_object">
<querytext>

select acs_mail_body__set_content_object (
  :body_id,				-- body_id 
  :content_item_id		-- content_item_id 
);

</querytext>
</fullquery>

 

 
<fullquery name="acs_mail_multipart_new.acs_mail_multipart_new">      
<querytext>

select acs_mail_multipart__new (
  :multipart_id,	    -- multipart_id 
  :multipart_kind,	    -- multipart_kind 
  'acs_mail_multipart', -- object_type
  now(),                -- creation_date
  :creation_user,	    -- creation_user 
  :creation_ip,		    -- creation_ip 
  null                  -- context_id
);

</querytext>
</fullquery>

 
 

<fullquery name="acs_mail_multipart_p.acs_mail_multipart_p">      
<querytext>

select acs_mail_multipart__multipart_p (:object_id);

</querytext>
</fullquery>


 


<fullquery name="acs_mail_multipart_add_content.acs_mail_multipart_add_content">
<querytext>

select acs_mail_multipart__add_content (
  :multipart_id,		-- multipart_id 
  :content_item_id		-- content_item_id 
);

</querytext>
</fullquery>


 
 

<fullquery name="acs_mail_link_new.acs_mail_link_new">      
<querytext>

select acs_mail_link__new (
  :mail_link_id,	-- mail_link_id 
  :body_id,			-- body_id 
  :context_id,		-- context_id 
  :creation_user,	-- creation_user 
  :creation_ip		-- creation_ip 
);

</querytext>
</fullquery>

 

 
<fullquery name="acs_mail_link_p.acs_mail_link_p">      
<querytext>

select acs_mail_link__link_p (:object_id);

</querytext>
</fullquery>

</queryset>
