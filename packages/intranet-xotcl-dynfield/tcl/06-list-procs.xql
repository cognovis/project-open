<?xml version="1.0"?>

<queryset>

<fullquery name="ams::list::get_list_id.get_list_id">
  <querytext>
        select list_id
          from ams_lists
         where object_type = :object_type
           and list_name = :list_name
  </querytext>
</fullquery>

</queryset>