<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="category_id_next_sequence">      
      <querytext>
      select 
  category_id_sequence.nextval 
      </querytext>
</fullquery>

 
<fullquery name="category_map_insert">      
      <querytext>
      insert into site_wide_category_map 
  (map_id, category_id,
  on_which_table, on_what_id, mapping_date, one_line_item_desc) 
  values (site_wide_cat_map_id_seq.nextval, :category_id, 'survsimp_surveys',
  :survey_id, current_timestamp, :one_line_item_desc)
      </querytext>
</fullquery>

 
</queryset>
