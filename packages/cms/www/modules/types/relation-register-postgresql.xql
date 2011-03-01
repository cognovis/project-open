<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_target_types">      
      <querytext>


  select
    lpad(' ', tree_level(ot1.tree_sortkey), '-') || ot1.pretty_name, 
        ot1.object_type
  from
    acs_object_types ot1, acs_object_types ot2
  where ot2.object_type = 'content_revision'
    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)

      </querytext>
</fullquery>

<fullquery name="register_rel_types">      
      <querytext>

	  
          select content_type__${register_method} (
	      :content_type,
	      :target_type,
	      :relation_tag,
              :min_n,
              :max_n
          );
          

      </querytext>
</fullquery>
 
</queryset>
