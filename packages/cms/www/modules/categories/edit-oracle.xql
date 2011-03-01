<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="edit_keyword">      
      <querytext>
      
    begin 
      content_keyword.set_heading(:keyword_id, :heading);
      content_keyword.set_description(:keyword_id, :description);
    end;
      
      </querytext>
</fullquery>

 
<fullquery name="get_info">      
      <querytext>
      
  select
    content_keyword.get_heading(:id) heading,
    content_keyword.get_description(:id) description,
    case when content_keyword.is_leaf(:id) = 't' then 'keyword' else 'category' end as what
  from
    dual
      </querytext>
</fullquery>

 
</queryset>
