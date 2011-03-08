<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="edit_keyword">      
      <querytext>


    begin 
      PERFORM content_keyword__set_heading(:keyword_id, :heading);
      PERFORM content_keyword__set_description(:keyword_id, :description);

      return null;
    end;
      
      </querytext>
</fullquery>

 
<fullquery name="get_info">      
      <querytext>
      
  select
    content_keyword__get_heading(:id) as heading,
    content_keyword__get_description(:id) as description,
    case when content_keyword__is_leaf(:id) = 't' then 'keyword' else 'category' end as what
  from
    dual

      </querytext>
</fullquery>

 
</queryset>
