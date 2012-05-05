# /packages/intranet-sencha/tcl/sencha-procs.tcl
#
# Copyright (C) 2003-2007 ]project-open[
# 
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Sencha Functionality
# ---------------------------------------------------------------------

ad_proc -public sencha_model {
    -object_type:required
} {
    Returns a Sencha model definition for the ]po[ object type
} {
    set supertypes [list]
    set otype $object_type
    set ctr 0
    while {"" != $otype} {
	if {"acs_object" == $otype} { break }
	lappend supertypes "'$otype'"
        set otype [db_string supertype "select supertype from acs_object_types where object_type = :otype" -default ""]
	incr ctr
	if {$ctr > 10} { 
	    ad_return_complaint 1 "Infinite loop"
	    ad_script_abort
	}
    }

    set dynfield_sql "
	select	*
	from	im_dynfield_attributes da,
		acs_attributes aa,
		im_dynfield_widgets dw
	where	da.acs_attribute_id = aa.attribute_id and
		da.widget_name = dw.widget_name and
		aa.object_type in ([join $supertypes ","])
    "
    set fields ""
    set validations ""
    db_foreach dynfields $dynfield_sql {
	switch $datatype {
	    integer	{ set type "int" }
	    boolean	{ set type "boolean" }
	    date	{ set type "date" }
	    string	{ set type "string" }
	    float	{ set type "float" }
	    number	{ set type "float" }
	    default	{ ad_return_complaint 1 "ACS datatype '$datatype' without mapping to Sencha data type" }
	}
	lappend fields "\t\t\t{name: \'$attribute_name\', type: '$type'}"
    }


    return "
	Ext.define('Person', {
		extend: 'Ext.data.Model',
		fields: \[\n[join $fields ",\n"]\n\t\t\],
		validations: \[\n[join $validations ",\n"]\n\t\t\],
	});
    "
}
