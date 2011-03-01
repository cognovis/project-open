<?xml version="1.0"?>

<queryset>

<fullquery name="get_search_string">
      <querytext>
  
    select search_text
    from category_search
    where query_id = :query_id

      </querytext>
</fullquery>

 
<fullquery name="get_search_result">
      <querytext>
  
    select s.category_id, s.synonym_id, r.similarity, s.name as synonym_name,
           s.synonym_p
    from category_search_results r, category_synonyms s
    where s.synonym_id = r.synonym_id
    and r.query_id = :query_id
    order by r.similarity desc, lower(s.name)

      </querytext>
</fullquery>

 
</queryset>
