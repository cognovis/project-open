# /packages/intranet-sencha/lib/margin-tracker.tcl
#
# Copyright (C) 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ----------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

# The following variables are expected in the environment
# defined by the calling /tcl/*.tcl libary:
#	program_id
#	diagram_width
#	diagram_height
#	sql	Defines the columns x_axis, y_axis, color and diameter

# Create a random ID for the diagram
set diagram_rand [expr round(rand() * 100000000.0)]
set diagram_id "margin_tracker_$diagram_rand"

# The diagram shows wrong if title is too short
while {[string length $title] < 30} {
    set title "&nbsp;$title&nbsp;"
}


set x_axis 0
set y_axis 0
set color "yellow"
set diameter 5
set title ""

set data_list {}
set i 0
db_foreach scatter_sql $sql {
    if {$i > 10} { continue }
    lappend data_list "{x_axis: $x_axis, y_axis: $y_axis, color: '$color', diameter: $diameter, caption: '$title'}"
    incr i
    
}


set data_json "\[\n"
append data_json [join $data_list ",\n"]
append data_json "\]\n"


# ad_return_complaint 1 "<pre>$data_json</pre>"