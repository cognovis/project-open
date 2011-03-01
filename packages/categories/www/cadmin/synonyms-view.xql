<?xml version="1.0"?>
<queryset>

<fullquery name="get_synonyms">
      <querytext>
      
    select s.synonym_id, s.name as synonym_name, l.label as language
    from category_synonyms s, ad_locales l
    where l.locale = s.locale
    and s.category_id = :category_id
    and s.synonym_p = 't'
    [template::list::orderby_clause -orderby -name synonyms]

      </querytext>
</fullquery>

 
</queryset>
