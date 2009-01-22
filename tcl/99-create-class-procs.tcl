ad_library {

	Initialize intranet dynfields
	
    @creation-date 2008-08-18
    @author  (malte.sussdorff@cognovis.de)
    @cvs-id 
}

# Initialize all object types which are linked from im_dynfield_type_attribute_map

# First get the object_types
set object_types [db_list object_types "select distinct object_type from acs_attributes aa, im_dynfield_attributes ida, im_dynfield_type_attribute_map tam where aa.attribute_id = ida.acs_attribute_id and ida.attribute_id = tam.attribute_id "]

# Now we need to go up for each of these and initialize the class

foreach object_type $object_types {
    ::im::dynfield::Class get_class_from_db -object_type $object_type
} 
 