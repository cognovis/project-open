ad_library {
    @creation-date 2008-08-21
    @author  (malte.sussdorff@cognovis.de)
    @cvs-id 
}

namespace eval im_dynfield {}

ad_proc -private im_dynfield::package_install {} {} {
     # Make sure acs_rels is correctly entered in acs_attributes so the relationship
     # Classes can work
     db_dml table "insert into acs_object_type_tables (object_type,table_name,id_column) values ('relationship','acs_rels','rel_id')"
     im_dynfield::attribute::add -attribute_name "object_id_one" -object_type relationship -datatype integer -pretty_name "Object ID One" -pretty_plural "Object ID One" -widget_name "integer" -table_name "acs_rels" -required_p "t"
    im_dynfield::attribute::add -attribute_name "object_id_two" -object_type relationship -datatype integer -pretty_name "Object ID Two" -pretty_plural "Object ID Two" -widget_name "integer" -table_name "acs_rels" -required_p "t"
    im_dynfield::attribute::add -attribute_name "rel_type" -object_type relationship -datatype string -pretty_name "Relationship Type" -pretty_plural "Relationship Type" -widget_name "textbox_medium" -table_name "acs_rels" -required_p "t"
    
    im_dynfield::attribute::add -attribute_name "object_role_id" -object_type im_biz_object_member -datatype integer -pretty_name "IM Biz Object Role" -pretty_plural "IM Biz Object Role" -widget_name "biz_object_member_type" -table_name "im_biz_object_members" -required_p "t"
    im_dynfield::attribute::add -attribute_name "percentage" -object_type im_biz_object_member -datatype integer -pretty_name "Percentage" -pretty_plural "Percentage" -widget_name "integer" -table_name "im_biz_object_members" -required_p "f"
}


