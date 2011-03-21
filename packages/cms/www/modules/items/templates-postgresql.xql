<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="allowed_set_p">      
      <querytext>
      
  select
    cms_permission__permission_p( module_id, :user_id, 'cm_write' )
  from
    cm_modules
  where
     key = 'types'

      </querytext>
</fullquery>

 
<fullquery name="get_iteminfo">      
      <querytext>
      
  select 
    object_type, pretty_name,
    content_item__get_title(:item_id,'f') as name
  from
    acs_object_types
  where 
    object_type = content_item__get_content_type(:item_id)

      </querytext>
</fullquery>

 
<fullquery name="get_reg_templates">      
      <querytext>
      
  select 
    template_id, use_context, 
    content_item__get_path( template_id, null ) as path,
    cms_permission__permission_p( template_id, :user_id, 'cm_examine')
      as can_read_template
  from 
    cr_item_template_map t
  where     
    t.item_id = :item_id
  order by 
    path, use_context

      </querytext>
</fullquery>

 
<fullquery name="get_type_templates">      
      <querytext>
      
  select 
    template_id, use_context, is_default,
    content_item__get_path( template_id, null ) as path,
    cms_permission__permission_p( template_id, :user_id, 'cm_examine') 
      as can_read_template,
    (select 1 
     from 
       cr_item_template_map itmap 
     where 
       itmap.template_id = t.template_id
     and 
       itmap.use_context = t.use_context
     and 
       itmap.item_id = :item_id) as already_registered_p
  from 
    cr_type_template_map t
  where 
    t.content_type = :content_type
  order by 
    path, use_context

      </querytext>
</fullquery>

 
</queryset>
