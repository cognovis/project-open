<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="set_release_period">      
      <querytext>
      begin 
                    content_item.set_release_period(
                      item_id => :item_id,
                      start_when => $start_when,
                      end_when => $end_when
                    );
                  end;
      </querytext>
</fullquery>

 
<fullquery name="check_status">      
      <querytext>
      
  select content_item.is_publishable( :item_id ) from dual
      </querytext>
</fullquery>

 
<fullquery name="check_published">      
      <querytext>
      
  select content_item.is_published( :item_id ) from dual
      </querytext>
</fullquery>

 
<fullquery name="get_info">      
      <querytext>
      
    select
      NVL(publish_status, 'production') as publish_status,
      to_char(NVL(start_when, sysdate), 'YYYY MM DD HH24 MI SS') start_when,
      to_char(NVL(end_when, sysdate + 365), 'YYYY MM DD HH24 MI SS') end_when
    from
      cr_items i, cr_release_periods r
    where
      i.item_id = :item_id
    and
      i.item_id = r.item_id (+)
      </querytext>
</fullquery>

 
</queryset>
