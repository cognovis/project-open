<?xml version="1.0"?>
<queryset>

<fullquery name="get_synonym">
      <querytext>
      
	    select name, locale as language
	    from category_synonyms
	    where synonym_id = :synonym_id
	    and synonym_p = 't'
	
      </querytext>
</fullquery>

 
</queryset>
