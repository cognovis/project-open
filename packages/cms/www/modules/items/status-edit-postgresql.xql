<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="set_release_period">      
      <querytext>

                select content_item__set_release_period(
                      :item_id,
                      $start_when,
                      $end_when
                    );
                  
      </querytext>
</fullquery>

 
<fullquery name="check_status">      
      <querytext>
      
  select content_item__is_publishable( :item_id ) 

      </querytext>
</fullquery>

 
<fullquery name="check_published">      
      <querytext>
      
  select content_item__is_published( :item_id ) 

      </querytext>
</fullquery>

 
<fullquery name="get_info">      
      <querytext>

    select
      coalesce(publish_status, 'production') as publish_status,
      to_char(coalesce(start_when, current_timestamp), 'YYYY MM DD HH24 MI SS') as start_when,
      to_char(coalesce(end_when, current_timestamp + interval '365 days'), 'YYYY MM DD HH24 MI SS') as end_when
    from
      cr_items i left outer join cr_release_periods r using (item_id)
    where
      i.item_id = :item_id

      </querytext>
</fullquery>

</queryset>
