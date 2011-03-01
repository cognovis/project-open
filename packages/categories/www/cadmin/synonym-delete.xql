<?xml version="1.0"?>
<queryset>

<fullquery name="get_synonyms_to_delete">
      <querytext>
      
    select s.name as synonym_name, l.label as language
    from category_synonyms s, ad_locales l
    where s.locale = l.locale
    and s.synonym_id in ([join $synonym_id ,])
    order by lower(l.label), lower(s.name)

      </querytext>
</fullquery>

 
</queryset>
