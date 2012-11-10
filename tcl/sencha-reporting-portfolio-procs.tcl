# /packages/sencha-reporting-portfolio/tcl/sencha-reporting-portfolio-procs.tcl
#
# Copyright (C) 2012 ]project-open[
# 
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}

# ----------------------------------------------------------------------
# Portlets
# ---------------------------------------------------------------------

ad_proc -public sencha_scatter_diagram {
    {-diagram_width 200 }
    {-diagram_height 200 }
    {-diagram_caption "" }
    -sql:required
} {
    Returns a HTML code with a Sencha scatter diagram.
    @param sql A sql statement returning the rows x_axis, 
	y_axis, color and diameter for each dot to be displayed.
} {
    # Choose the version and type of the sencha libs
    set version "v407"
    set ext "ext-all-debug-w-comments.js"

    # Make sure the Sencha library is loaded
    template::head::add_css -href "/sencha-$version/ext-all.css" -media "screen" -order 1
#    template::head::add_javascript -src "/sencha-$version/bootstrap.js" -order 2
    template::head::add_javascript -src "/sencha-$version/$ext" -order 2

    set params [list \
		    [list diagram_width $diagram_width] \
		    [list diagram_height $diagram_height] \
		    [list diagram_caption $diagram_caption] \
		    [list sql $sql] \
    ]

    set result [ad_parse_template -params $params "/packages/sencha-reporting-portfolio/lib/scatter-diagram"]
    return [string trim $result]
}

ad_proc -public sencha_milestone_tracker {
    -project_id:required
    {-diagram_width 300 }
    {-diagram_height 300 }
    {-diagram_caption "" }
    {-diagram_title "Milestones" }
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

    # Choose the version and type of the sencha libs
    set version "v407"
    set ext "ext-all-debug-w-comments.js"

    # Make sure the Sencha library is loaded
    template::head::add_css -href "/sencha-$version/ext-all.css" -media "screen" -order 1
#    template::head::add_javascript -src "/sencha-$version/bootstrap.js" -order 2
    template::head::add_javascript -src "/sencha-$version/$ext" -order 2

    set ext "ext-all-debug-w-comments.js"

    set params [list \
		    [list project_id $project_id] \
		    [list diagram_width $diagram_width] \
		    [list diagram_height $diagram_height] \
		    [list diagram_title $diagram_title] \
		    [list diagram_caption $diagram_caption] \
    ]

    set result [ad_parse_template -params $params "/packages/sencha-reporting-portfolio/lib/milestone-tracker"]
    return [string trim $result]
}




ad_proc -public sencha_project_timeline {
    {-diagram_width 1000 }
    {-diagram_height 400 }
    {-diagram_caption "Project Timeline" }
    {-diagram_start_date ""}
    {-diagram_end_date ""}
    {-diagram_user_id ""}
    {-diagram_availability ""}
} {
    Returns a HTML code with a Sencha project timelinediagram.
    The timeline shows the resource requirements over time.
} {
    # Choose the version and type of the sencha libs
    set version "v407"
    set ext "ext-all-debug-w-comments.js"

    # Make sure the Sencha library is loaded
    template::head::add_css -href "/sencha-$version/ext-all.css" -media "screen" -order 1
    template::head::add_javascript -src "/sencha-$version/$ext" -order 2

    set params [list \
		    [list diagram_width $diagram_width] \
		    [list diagram_height $diagram_height] \
		    [list diagram_caption $diagram_caption] \
		    [list diagram_start_date $diagram_start_date] \
		    [list diagram_end_date $diagram_end_date] \
		    [list diagram_user_id $diagram_user_id] \
		    [list diagram_availability $diagram_availability] \
    ]

    set result [ad_parse_template -params $params "/packages/sencha-reporting-portfolio/lib/project-timeline"]
    return [string trim $result]
}





ad_proc -public sencha_project_eva {
    -project_id:required
    {-diagram_width 1000 }
    {-diagram_height 400 }
    {-diagram_caption "Project EVA" }
} {
    Returns a HTML code with a Sencha EVA diagram.
} {
    # Choose the version and type of the sencha libs
    set version "v407"
    set ext "ext-all-debug-w-comments.js"

    # Make sure the Sencha library is loaded
    template::head::add_css -href "/sencha-$version/ext-all.css" -media "screen" -order 1
    template::head::add_javascript -src "/sencha-$version/$ext" -order 2

    set params [list \
		    [list main_project_id $project_id] \
		    [list diagram_width $diagram_width] \
		    [list diagram_height $diagram_height] \
		    [list diagram_caption $diagram_caption]
    ]

    set result [ad_parse_template -params $params "/packages/sencha-reporting-portfolio/lib/project-eva"]
    return [string trim $result]
}



ad_proc -public sencha_main_project_colors {
} {
    Returns a hash with random RGB colors for every main project
} {
    return [util_memoize sencha_main_project_colors_helper 1200]
}


ad_proc -public sencha_main_project_colors_helper {
} {
    Returns a hash with random RGB colors for every main project
} {
    set hex_list {0 1 2 3 4 5 6 7 8 9 A B C D E F}

    set main_project_ids [db_list main_project_ids "
	select	p.project_id
	from	im_projects p
	where	p.parent_id is null and
		p.project_type_id not in ([im_project_type_task], [im_project_type_ticket])
	order by p.project_id
    "]

    foreach pid $main_project_ids {
	set r [expr int(random() * 256)]
	set g [expr int(random() * 256)]
	set b [expr int(random() * 256)]
	
	# Convert the RGB values back into a hex color string
	set color ""
	append color [lindex $hex_list [expr $r / 16]]
	append color [lindex $hex_list [expr $r % 16]]
	append color [lindex $hex_list [expr $g / 16]]
	append color [lindex $hex_list [expr $g % 16]]
	append color [lindex $hex_list [expr $b / 16]]
	append color [lindex $hex_list [expr $b % 16]]

	set hash($pid) $color
    }
    return [array get hash]
}

