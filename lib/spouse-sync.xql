<?xml version="1.0"?>
<queryset>

<fullquery name="get_attributes">
    <querytext>
        select pretty_name,
               attribute_id
          from acs_attributes
         where attribute_id in ([template::util::tcl_to_sql_list $attribute_ids]) 
    </querytext>
</fullquery>

<fullquery name="get_party_value_id">
    <querytext>
        select value_id
          from ams_attribute_values
         where object_id = :party_revision_id
           and attribute_id = :attribute_id 
    </querytext>
</fullquery>

<fullquery name="get_spouse_value_id">
    <querytext>
        select value_id
          from ams_attribute_values
         where object_id = :spouse_revision_id
           and attribute_id = :attribute_id 
    </querytext>
</fullquery>

</queryset>

