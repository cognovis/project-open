<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="new_content_item">      
      <querytext>
     
    select content_item__new(varchar :name, 
                             :context_id, 
                             :item_id, 
                             null,
                             current_timestamp, 
                             null,
                             NULL,
                             '[ns_conn peeraddr]', 
                             'content_item',
                             'content_revision',
                             null,
                             null,
                             'text/plain',
                             null,
                             null,
                             'text'); 

      </querytext>
</fullquery>

 
<fullquery name="new_revision">      
      <querytext>

    select content_revision__new(:title, 
                                 :description, 
                                 $publish_date, 
                                 :mime_type, 
                                 NULL, 
                                 :text, 
--                                 'content_revision', 
                                 :item_id, 
                                 :revision_id,
                                  now(),
                                  null,
                                  null,
                                  null);

      </querytext>
</fullquery>

<fullquery name="get_item_id">      
      <querytext>

        select acs_object_id_seq.nextval

      </querytext>
</fullquery>

<fullquery name="get_revision_id">      
      <querytext>

        select acs_object_id_seq.nextval

      </querytext>
</fullquery>
 
</queryset>
