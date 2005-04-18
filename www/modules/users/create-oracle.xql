<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="new_group">      
      <querytext>
      begin :1 := acs_group.new(
    group_id => :group_id, 
    group_name => :group_name, 
    email => :email,
    url => :url,
    creation_user => :user_id, 
    creation_ip => :ip ); end;
      </querytext>
</fullquery>

 
<fullquery name="new_rel">      
      <querytext>
      begin :1 := composition_rel.new(
    object_id_one => :parent_id,
    object_id_two => :group_id,
    creation_user => :user_id, 
    creation_ip => :ip ); end;
      </querytext>
</fullquery>

 
<fullquery name="get_group_id">      
      <querytext>
      
    select acs_object_id_seq.nextval from dual
  
      </querytext>
</fullquery>

 
</queryset>
