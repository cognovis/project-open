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
    ]

    set result [ad_parse_template -params $params "/packages/sencha-reporting-portfolio/lib/project-timeline"]
    return [string trim $result]
}
