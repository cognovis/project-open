<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="new_revision">      
      <querytext>
      
      begin
      :1 := content_revision.new (
        item_id       => :item_id,
        title         => :title,
        description   => :description,
        mime_type     => :mime_type,
        creation_user => :user_id,
        creation_ip   => :ip_address
      );
      end;
    
      </querytext>
</fullquery>

 
<fullquery name="update_content">      
      <querytext>
      
          update cr_revisions
            set content = empty_blob()
            where revision_id = $revision_id
            returning content into :1
      </querytext>
</fullquery>

 
</queryset>
