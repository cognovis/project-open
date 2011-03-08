<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="get_subscrs">
    <querytext>
        select s.subscr_id,
           s.timeout,
           person__name(o.creation_user) as creator,
           to_char(s.lastbuild,'YYYY-MM-DD HH24:MI:SS') as lastbuild_ansi,
           s.last_ttb,
           s.channel_title,
           s.channel_link
    from rss_gen_subscrs s,
         acs_objects o
    where o.object_id = s.subscr_id $maybe_restrict_to_user
    order by s.last_ttb desc
    </querytext>
  </fullquery>

</queryset>
