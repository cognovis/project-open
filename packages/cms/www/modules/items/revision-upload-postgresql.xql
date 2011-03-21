<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="new_content">      
      <querytext>

        select content_item__new(
          varchar :name, 
          :parent_id, 
          null,
          now(),
          [User::getID],
          null,          
          '[ns_conn peeraddr]',
          'content_item',
          :content_type,
          null,
          null,
          'text/plain',
          null,
          null,
          'text');
      
      </querytext>
</fullquery>

 
<fullquery name="insert_content">      
      <querytext>

--      FIX ME LOB
insert into cr_xml_docs 
  values ($revision_id, empty_lob()) returning doc into :1

      </querytext>
</fullquery>

 
<fullquery name="import_xml">      
      <querytext>

        select content_revision__import_xml(:item_id, :revision_id, :revision_id)
  
      </querytext>
</fullquery>

 
<fullquery name="get_new_item">      
      <querytext>
      
      select 
        coalesce(content_item__get_path(:parent_id,null), '/') as item_path,
        pretty_name as content_type_name
      from
        acs_object_types
      where
        object_type = :content_type
    
      </querytext>
</fullquery>

<fullquery name="get_revision_id">      
      <querytext>

        select acs_object_id_seq.nextval
      
      </querytext>
</fullquery>
 
</queryset>
