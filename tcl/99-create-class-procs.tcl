ad_library {

	Initialize intranet dynfields
	
    @creation-date 2008-08-18
    @author  (malte.sussdorff@cognovis.de)
    @cvs-id 
}

# Get the OpenACS version
set ver_sql "select substring(max(version_name),1,3) from apm_package_versions where package_key = 'acs-kernel'"
set openacs54_p [string equal "5.4" [util_memoize [list db_string ver $ver_sql ]]]

if {$openacs54_p} {

# Initialize all object types which are linked from im_dynfield_attributes,
# plus some standard classes

# First get the object_types
set object_types [db_list object_types "
	select distinct 
		object_type 
	from	acs_attributes aa, 
		im_dynfield_attributes ida
	where	aa.attribute_id = ida.acs_attribute_id
   UNION
	select	object_type
	from	acs_object_types
	where	object_type in (
			'im_office', 'im_company', 'im_project', 'im_conf_item', 'im_timesheet_task',
			'im_ticket', 'im_expense_bundle', 'im_material', 'im_report', 'im_user_absence',
			'person'
		)
"]

# Now we need to go up for each of these and initialize the class

foreach object_type $object_types {
    ns_log Notice "intranet-dynfield/tcl/99-create-class-procs.tcl: ::im::dynfield::Class get_class_from_db -object_type $object_type"
    ::im::dynfield::Class get_class_from_db -object_type $object_type
} 

}