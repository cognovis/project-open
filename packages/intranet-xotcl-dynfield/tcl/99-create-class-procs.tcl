# packages/intranet-xo-dynfield/tcl/99-create-class-procs.tcl
#
# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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

# Initialize the Cr classes

set object_types [db_list object_types "select object_type from acs_object_types where supertype ='::im::dynfield::CrItem'"]
foreach object_type $object_types {
    ns_log Notice "intranet-dynfield/tcl/99-create-class-procs.tcl: ::im::dynfield::CrClass get_class_from_db -object_type $object_type"
    ::im::dynfield::CrClass get_class_from_db -object_type $object_type
} 

