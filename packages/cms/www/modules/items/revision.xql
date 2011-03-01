<?xml version="1.0"?>
<queryset>

<fullquery name="get_count">      
      <querytext>
      
  select count(*) from cr_revisions where item_id = :item_id

      </querytext>
</fullquery>

 
<fullquery name="get_attr_values">      
      <querytext>
      
      select 
        [join $attr_columns ", "]
      from
        [join $attr_tables ", "]
      where
        [join $column_id_cons " and "]
      </querytext>
</fullquery>

 
</queryset>
