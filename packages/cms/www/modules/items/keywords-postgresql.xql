<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="get_keywords">      
      <querytext>

        select
             keyword_id,
             content_keyword__get_heading(keyword_id) as heading,
             coalesce(content_keyword__get_description(keyword_id),
                '-') as description
           from
             cr_item_keyword_map
           where
             item_id = :item_id
           order by
             heading

      </querytext>
</fullquery>

</queryset>
