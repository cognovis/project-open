<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_info">      
      <querytext>
      
    select 
      content_keyword__is_leaf(:id) as is_leaf,
      content_keyword__get_heading(:id) as heading,
      content_keyword__get_description(:id) as description,
      content_keyword__get_path(:id) as path
    from 
      dual

      </querytext>
</fullquery>

 
<fullquery name="get_items">      
      <querytext>
      
  select
    keyword_id,
    content_keyword__is_leaf(keyword_id) as is_leaf,
    content_keyword__get_heading(keyword_id) as heading,
    (select count(*) from cr_item_keyword_map m
      where m.keyword_id = k.keyword_id) as item_count
  from
    cr_keywords k
  where
    $where_clause
  order by
    is_leaf, heading

      </querytext>
</fullquery>

 
</queryset>
