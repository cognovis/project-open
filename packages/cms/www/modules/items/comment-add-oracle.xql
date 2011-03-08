<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="new_entry">      
      <querytext>
      
    begin
      :1 := journal_entry.new(
                             journal_id => :journal_id,
                             object_id => :object_id,
                             action => 'comment',
                             action_pretty => 'Comment',
                             creation_user => :user_id,
                             creation_ip  => :ip_address,
                             msg => :msg );
    end;
      </querytext>
</fullquery>

 
<fullquery name="get_title">      
      <querytext>
      
  select content_item.get_title(:item_id) from dual

      </querytext>
</fullquery>

 
<fullquery name="get_journal_id">      
      <querytext>
      
    select acs_object_id_seq.nextval from dual
  
      </querytext>
</fullquery>

 
</queryset>
