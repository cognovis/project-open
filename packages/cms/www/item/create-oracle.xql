<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="new_content_item">      
      <querytext>
      begin 
    :1 := content_item.new(:name, :context_id, :item_id, sysdate, NULL,
                           '[ns_conn peeraddr]', 'content_item'); 
  end;
      </querytext>
</fullquery>

 
<fullquery name="new_revision">      
      <querytext>
      begin 
    :1 := content_revision.new(:title, :description, $publish_date, 
                               :mime_type, NULL, :text, 'content_revision', 
                               :item_id, :revision_id);
  end;
      </querytext>
</fullquery>

<fullquery name="get_item_id">      
      <querytext>

        select acs_object_id_seq.nextval from dual

      </querytext>
</fullquery>

<fullquery name="get_revision_id">      
      <querytext>

        select acs_object_id_seq.nextval from dual

      </querytext>
</fullquery>

 
</queryset>
