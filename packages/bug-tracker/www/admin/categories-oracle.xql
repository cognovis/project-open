<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_categories">
  <querytext>
        select child.keyword_id as child_id,
               child.heading as child_heading,
               parent.keyword_id as parent_id,
               parent.heading as parent_heading,
               decode(child.keyword_id, null, 0, 
                  (select count(b.bug_id) 
                   from   bt_bugs b 
                   where  b.project_id = :package_id 
                   and    content_keyword.is_assigned(b.bug_id, child.keyword_id, 'none') = 't'
                  )
               ) as num_bugs,
               (select content_keyword.is_leaf(parent.keyword_id) from dual) as is_leaf,
               (select count(def.keyword_id) 
                from   bt_default_keywords def 
                where  def.project_id = :package_id 
                and    def.parent_id = parent.keyword_id 
                and    def.keyword_id = child.keyword_id
               ) as default_p
        from   cr_keywords parent,
               cr_keywords child
        where  parent.parent_id = :project_root_keyword_id
        and    child.parent_id (+) = parent.keyword_id
        order  by parent.heading, child.heading
  </querytext>
</fullquery>
 
</queryset>
