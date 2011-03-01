<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="new_entry">      
      <querytext>

                select journal_entry__new(
                             :journal_id,
                             :object_id,
                             'comment',
                             'Comment',
                             now(),
                             :user_id,
                             :ip_address,
                             :msg );
    
      </querytext>
</fullquery>

 
<fullquery name="get_title">      
      <querytext>
      
  select content_item__get_title(:item_id, 'f') 

      </querytext>
</fullquery>

 
<fullquery name="get_journal_id">      
      <querytext>
      
    select acs_object_id_seq.nextval 
  
      </querytext>
</fullquery>

 
</queryset>
