<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="check_synonyms_for_delete">
      <querytext>
      
    select s.synonym_id
    from category_synonyms s, categories c
    where s.synonym_id in ([join $synonym_id ,])
    and c.category_id = s.category_id
    and acs_permission__permission_p(c.tree_id,:user_id,'category_tree_write') = 't'
    and s.synonym_p = 't'

      </querytext>
</fullquery>

 
</queryset>
