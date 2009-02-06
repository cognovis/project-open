ad_library {

	Initialize intranet dynfields
	
    @creation-date 2008-08-18
    @author  (malte.sussdorff@cognovis.de)
    @cvs-id 
}

# Initialize all object types which are linked from im_dynfield_attributes,
# plus some standard classes

# First get the object_types
set object_types [db_list object_types "
	select distinct 
		object_type 
	from	acs_attributes aa, 
		im_dynfield_attributes ida
	where	aa.attribute_id = ida.acs_attribute_id
UNION	select 'im_office'
UNION	select 'im_company'
UNION	select 'im_project'
UNION	select 'im_conf_item'
UNION	select 'im_timesheet_task'
UNION	select 'im_ticket'
UNION	select 'im_expense_bundle'
UNION	select 'im_material'
UNION	select 'im_report'
UNION	select 'im_user_absence'
UNION	select 'person'
"]

# Now we need to go up for each of these and initialize the class

foreach object_type $object_types {
    ::im::dynfield::Class get_class_from_db -object_type $object_type
} 
 