<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="delete_subscr">
    <querytext>
    select rss_gen_subscr__delete (
        :subscr_id
    )
    </querytext>
  </fullquery>

</queryset>
