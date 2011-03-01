<?xml version="1.0"?>
<queryset>

<fullquery name="check_translation_existance">      
      <querytext>
      
	select name, description
	from category_translations
	where category_id = :category_id
	and locale = :locale
    
      </querytext>
</fullquery>

 
<fullquery name="get_default_translation">      
      <querytext>
      
	    select name, description
	    from category_translations
	    where category_id = :category_id
	    and locale = :default_locale
	
      </querytext>
</fullquery>

 
</queryset>
