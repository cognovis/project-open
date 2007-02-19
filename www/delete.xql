<?xml version="1.0"?>

<queryset>

  <fullquery name="subscr_info">
    <querytext>
    select summary_context_id,
           channel_title,
           channel_link
    from rss_gen_subscrs
    where subscr_id = :subscr_id
    </querytext>
  </fullquery>

</queryset>
