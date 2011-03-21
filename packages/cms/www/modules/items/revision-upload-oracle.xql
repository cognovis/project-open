<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="new_content">      
      <querytext>
      begin 
      :item_id := content_item.new(
          name          => :name, 
          parent_id     => :parent_id, 
          content_type  => :content_type,
          creation_user => [User::getID],
          creation_ip   => '[ns_conn peeraddr]' ); 
      end;
      </querytext>
</fullquery>

 
<fullquery name="insert_content">      
      <querytext>
      insert into cr_xml_docs 
  values ($revision_id, empty_clob()) returning doc into :1
      </querytext>
</fullquery>

 
<fullquery name="import_xml">      
      <querytext>
      begin
    :revision_id := content_revision.import_xml(
      :item_id, :revision_id, :revision_id);
  end;
      </querytext>
</fullquery>

 
<fullquery name="get_new_item">      
      <querytext>
      
      select 
        NVL(content_item.get_path(:parent_id), '/') as item_path,
        pretty_name as content_type_name
      from
        acs_object_types
      where
        object_type = :content_type
    
      </querytext>
</fullquery>

<fullquery name="get_revision_id">      
      <querytext>

        select acs_object_id_seq.nextval from dual
      
      </querytext>
</fullquery>
 
</queryset>
