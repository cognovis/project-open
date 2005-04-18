<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="unrelate_item">      
      <querytext>
      
  begin
  content_item.unrelate ( 
      rel_id => :rel_id 
  );
  end;
      </querytext>
</fullquery>

 
</queryset>
