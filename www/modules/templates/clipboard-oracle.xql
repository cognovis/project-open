<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_templates">      
      <querytext>

        select
           template_id, content_item.get_path(template_id) path
        from
           cr_templates
        where
          template_id in ($in_list)

      </querytext>
</fullquery>

  
</queryset>
