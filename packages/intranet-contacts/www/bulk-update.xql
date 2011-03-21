<?xml version="1.0"?>
<queryset>

<fullquery name="get_attributes">
    <querytext>
        select pretty_name,
               attribute_id
          from ams_attributes
         where object_type in ([ams::object_parents -sql -object_type $object_type])
           and widget in (select widget from ams_widgets where value_method in ( 'ams_value__time', 'ams_value__options'))
    </querytext>
</fullquery>

</queryset>
