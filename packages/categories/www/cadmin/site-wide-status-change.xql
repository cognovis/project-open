<?xml version="1.0"?>
<queryset>

<fullquery name="toggle_site_wide_status">      
      <querytext>
      
    update category_trees
    set site_wide_p = case when :action = '1' then 't' else 'f' end
    where tree_id  = :tree_id

      </querytext>
</fullquery>

 
</queryset>
