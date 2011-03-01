<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>
 
<fullquery name="publish::track_publish_status.tps_get_items_multilist">      
      <querytext>
      
            select 
	      distinct i.item_id, i.live_revision 
            from 
      	      cr_items i, cr_release_periods p
            where
  	      i.publish_status = 'ready'
             and
	      i.live_revision is not null
             and 
              i.item_id = p.item_id
             and
              (sysdate between p.start_when and p.end_when)
          
      </querytext>
</fullquery>

 
<fullquery name="publish::track_publish_status.tps_get_items_onelist">      
      <querytext>
      
            select 
  	      distinct i.item_id
            from 
  	      cr_items i, cr_release_periods p
            where
	      i.publish_status = 'live'
            and
  	      i.live_revision is not null
            and 
              i.item_id = p.item_id     
            and 
	      not exists (select 1 from cr_release_periods p2
		          where p2.item_id = i.item_id
		           and (sysdate between p2.start_when and p2.end_when)
	                 )
            
      </querytext>
</fullquery>

 
</queryset>
