<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="create_subscr">
    <querytext>
	begin
          :1 := rss_gen_subscr.new (
	    :subscr_id,				-- subscr_id
            :impl_id,				-- impl_id
            :summary_context_id,		-- summary_context_id
            :timeout,			        -- timeout
            null,				-- lastbuild
            'rss_gen_subscr',		        -- object_type
            sysdate,				-- creation_date
            :creation_user,			-- creation_user
            :creation_ip,			-- creation_ip
            :summary_context_id			-- context_id
	);
      end

    </querytext>
  </fullquery>


</queryset>
