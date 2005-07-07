<?xml version="1.0"?>

<queryset>
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="acs_mail_post_request">
      <querytext>
	select acs_mail_nt__post_request(:party_from, :party_to, :subject, :message)
      </querytext>
  </fullquery>

  <fullquery name="spam_full_sql">
      <querytext>

    select
        p2.*,
        parties.email as user_email,
        persons.first_names as user_first_names,
        persons.last_name as user_last_name,
        persons.first_names || ' ' || persons.last_name as user_name
    from
        parties
        left join persons on parties.party_id = person_id
        join ($sql_query) p2 on p2.party_id = parties.party_id

      </querytext>
  </fullquery>
   
  <fullquery name="create_text_item">
        <querytext>
  	select content_item__new (:subject, 		-- name
  				  null, 		-- parent_id
  				  null, 		-- item_id
  				  null,			-- locale
  				  now(),		-- creation_date
  				  :user_id,		-- creation_user
  				  null,			-- context_id
  				  :ip_addr,			-- creation_ip
  				  'acs_object', 		-- item_subtype
    				  'content_revision',			-- content_type
				  :subject, 		-- title
				  null,			-- description
				  :content_mime_type, 	-- mime_type 
				  null,			-- nls_language
				  :content, 		-- text
				  null,			-- data
				  null,			-- relation_tag
				  null,			-- is_live
				  :storage_type		-- storage_type
				  )
        </querytext>
  </fullquery>
  
  
  <fullquery name="create_file_item">
          <querytext>
    	select content_item__new (:unique_client_filename,  -- name
    				  null, 		-- parent_id
    				  null, 		-- item_id
    				  null,			-- locale
    				  now(),		-- creation_date
    				  :user_id,		-- creation_user
    				  null,			-- context_id
    				  :ip_addr,		-- creation_ip
    				  'acs_object', 		-- item_subtype
    				  'content_revision',			-- content_type
  				  :client_filename,	-- title
  				  null,			-- description
  				  :guessed_file_type, 	-- mime_type 
  				  null,			-- nls_language
  				  :content_file, 		-- text
  				  null,			-- data
  				  null,			-- relation_tag
  				  null,			-- is_live
  				  :storage_type		-- storage_type
  				  )
          </querytext>
  </fullquery>
  
  <fullquery name="create_revision">
            <querytext>
      	select content_revision__new (:client_filename,   	-- title 
      				      null,			-- description
      				      now(),			-- publish_date
				      :guessed_file_type, 	-- mime_type
				      null,			-- nls_language
		        	      null,	  	-- data
				      :attachment_item_id,	-- item_id
				      null,			-- revision_id
				      now(),			-- creation_date
		 		      :user_id,			-- creation_user
				      :ip_addr	 		-- creation_ip
    				  )
            </querytext>
  </fullquery>
  
  <fullquery name="update_revision">
              <querytext>
        	select content_item__set_live_revision(:revision_id)
              </querytext>
  </fullquery>
  
  <fullquery name="queue_the_mail">
                <querytext>
          	select acs_mail_queue_message__new (
							null,             -- p_mail_link_id
							:body_id,         -- p_body_id
							null,             -- p_context_id
							now(),          -- p_creation_date
							:user_id,  -- p_creation_user
							:ip_addr,         -- p_creation_ip
							'acs_mail_link'   -- p_object_type
					)
                </querytext>
  </fullquery>
</queryset>





