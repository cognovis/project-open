<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_keywords">      
      <querytext>
select
             keyword_id,
             content_keyword.get_heading(keyword_id) heading,
             NVL(content_keyword.get_description(keyword_id),
                '-') description
           from
             cr_item_keyword_map
           where
             item_id = :item_id
           order by
             heading
      </querytext>
</fullquery>

</queryset>
