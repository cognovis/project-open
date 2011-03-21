<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="register_templates">      
      <querytext>

        select content_type__register_template(
                       :content_type,
	               :template_id,
	               :context,
                       'f');
                
      </querytext>
</fullquery>


<fullquery name="get_content_templates">      
      <querytext>

  select 
    template_id, 
    content_item__get_path( template_id, content_template__get_root_folder() ) 
      as name
  from 
    cr_templates t, cr_items i
  where 
    t.template_id = i.item_id
  and not exists (
    select 1 
    from 
      cr_type_template_map
    where 
      template_id = t.template_id
    and 
      content_type = :content_type )
  and 
    $marked_templates_sql

      </querytext>
</fullquery>
 
</queryset>
