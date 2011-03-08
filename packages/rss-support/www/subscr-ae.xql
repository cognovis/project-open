<?xml version="1.0"?>

<queryset>

  <fullquery name="subscr_id_from_impl_and_context">
    <querytext>
        select subscr_id
	from rss_gen_subscrs
        where impl_id = :impl_id
        and summary_context_id = :summary_context_id
    </querytext>
  </fullquery>

  <fullquery name="subscr_info">
    <querytext>
        select impl_id,
	       summary_context_id,
	       timeout,
               channel_title,
               channel_link
	from rss_gen_subscrs
	where subscr_id = :subscr_id
    </querytext>
  </fullquery>

</queryset>
