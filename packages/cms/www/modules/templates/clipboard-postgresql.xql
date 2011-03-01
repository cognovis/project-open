<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_templates">      
      <querytext>

        select
           template_id, content_item__get_path(template_id,null) as path
        from
           cr_templates
        where
          template_id in ($in_list)

      </querytext>
</fullquery>
  
</queryset>
