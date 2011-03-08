<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="new_keyword">      
      <querytext>
      
    begin :1 := content_keyword.new(
      heading => :heading, 
      description => :description, 
      keyword_id => :keyword_id,
      creation_user => :user_id,
      creation_ip => :ip$pid); end;
      </querytext>
</fullquery>

 
<fullquery name="get_keyword_id">      
      <querytext>
      
    select acs_object_id_seq.nextval from dual
  
      </querytext>
</fullquery>

<partialquery name="pid">      
      <querytext>      
         ,parent_id => :parent_id  
      </querytext>
</partialquery>

 
</queryset>
