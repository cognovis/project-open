<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="create_subscr">
    <querytext>
	select rss_gen_subscr__new (
	    :subscr_id,				-- subscr_id
            :impl_id,				-- impl_id
            :summary_context_id,		-- summary_context_id
            :timeout,			        -- timeout
            null,				-- lastbuild
            'rss_gen_subscr',		        -- object_type
            now(),				-- creation_date
            :creation_user,			-- creation_user
            :creation_ip,			-- creation_ip
            :summary_context_id			-- context_id
	)

    </querytext>
  </fullquery>

</queryset>
