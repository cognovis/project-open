# /packages/intranet-sencha/tcl/intranet-sencha-procs.tcl
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

ad_proc -public im_sencha_model {
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

# ----------------------------------------------------------------------
# Portlets
# ---------------------------------------------------------------------

ad_proc -public im_sencha_scatter_diagram {
    {-diagram_width 200 }
    {-diagram_height 200 }
    {-title "" }
    -sql:required
} {
    Returns a HTML code with a Sencha scatter diagram.
    @param sql A sql statement returning the rows x_axis, 
	y_axis, color and diameter for each dot to be displayed.
} {
    # Make sure the Sencha library is loaded
    template::head::add_css -href "/intranet-sencha/css/ext-all.css" -media "screen" -order 1
    template::head::add_javascript -src "/intranet-sencha/js/bootstrap.js" -order 2
    template::head::add_javascript -src "/intranet-sencha/js/ext-all.js" -order 2

    set params [list \
		    [list diagram_width $diagram_width] \
		    [list diagram_height $diagram_height] \
		    [list title $title] \
		    [list sql $sql] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-sencha/lib/scatter-diagram"]
    return [string trim $result]
}



ad_proc -public im_sencha_milestone_tracker {
    -project_id:required
    {-diagram_width 300 }
    {-diagram_height 300 }
    {-title "Milestones" }
} {
    Returns a HTML code with a Sencha line diagram representing
    the evolution of the project's milestones (sub-projects marked
    as milestones or with a type that is a sub-type of milestone).
    @param project_id The project to show
} {
    # Check if the project is a main project and abort otherwise
    # We only want to show this diagram in a main project.
    set parent_id [db_string parent "select parent_id from im_projects where project_id = :project_id" -default ""]
    if {"" != $parent_id} { return "" }

    # Make sure the Sencha library is loaded
    template::head::add_css -href "/intranet-sencha/css/ext-all.css" -media "screen" -order 1
    template::head::add_javascript -src "/intranet-sencha/js/bootstrap.js" -order 2
    template::head::add_javascript -src "/intranet-sencha/js/ext-all.js" -order 2

    set params [list \
		    [list project_id $project_id] \
		    [list diagram_width $diagram_width] \
		    [list diagram_height $diagram_height] \
		    [list title $title] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-sencha/lib/milestone-tracker"]
    return [string trim $result]
}
