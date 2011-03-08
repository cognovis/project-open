<?xml version="1.0"?>

<queryset>

    <fullquery name="intranet-contacts::object_type_pretty.object_type_pretty">
        <querytext>
            select pretty_name from acs_object_types where object_type = :object_type
        </querytext>
    </fullquery>

</queryset>

