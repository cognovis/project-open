<?xml version="1.0"?>
<queryset>

<fullquery name="categorized_faq">      
  <querytext>
    select entry_id, faq_id, question, answer, sort_key
    from faq_q_and_as qa, category_object_map com
    where faq_id = :faq_id and
	com.object_id = qa.entry_id and
	com.category_id = :category_id
    order by sort_key
  </querytext>
</fullquery>

<fullquery name="uncategorized_faq">
  <querytext>
    select entry_id, faq_id, question, answer, sort_key
    from faq_q_and_as
    where faq_id = :faq_id
    order by sort_key  
  </querytext>
</fullquery>

<fullquery name="faq_categories">
  <querytext>
	select c.category_id as category_id, c.tree_id
	from   categories c, category_tree_map ctm
	where  ctm.tree_id = c.tree_id
	and    ctm.object_id = :package_id
  </querytext>
</fullquery>

</queryset>
