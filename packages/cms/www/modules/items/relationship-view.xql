<?xml version="1.0"?>
<queryset>

<fullquery name="get_value">      
      <querytext>
      
    select $what from $a_row(table_name) 
      where $a_row(id_column) = :rel_id
      </querytext>
</fullquery>

 
</queryset>
