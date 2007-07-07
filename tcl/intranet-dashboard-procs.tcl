# /packages/intranet-reporting-dashborad/tcl/intranet-reporting-dashboard-procs.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Common procedures for Dashboard
    @author frank.bergmann@project-open.com
}

# ----------------------------------------------------------------------
# Define a color bar from red to blue or similar...
# ----------------------------------------------------------------------

ad_proc im_dashboard_pie_colors { 
    { -max_entries 8 }
    { -red_start 0 }
    { -red_end 255 }
    { -blue_start 255 }
    { -blue_end 0 }
    { -green_start 128 }
    { -green_end 128 }
} {
    Returns an array with color codes from 0.. $max_entries
    (max_entries+1 in total)
} {

    # Aux string for hex conversions
    set h "0123456789ABCDEF"
    set max [expr $max_entries + 1]

    set blue_incr [expr 1.0 * ($blue_end - $blue_start) / $max]
    set red_incr [expr 1.0 * ($red_end - $red_start) / $max]
    set green_incr [expr 1.0 * ($green_end - $green_start) / $max]

    for {set i 0} {$i <= $max_entries} {incr i} {
        set blue [expr round($blue_start + round($i*$blue_incr))]
        set red [expr round($red_start + round($i*$red_incr))]
        set green [expr round($green_start + round($i*$green_incr))]
    
        set red_low [expr $red % 16]
        set red_high [expr round($red / 16)]
        set blue_low [expr $blue % 16]
        set blue_high [expr round($blue / 16)]
        set green_low [expr $green % 16]
        set green_high [expr round($green / 16)]
    
        set col "\#[string range $h $red_high $red_high][string range $h $red_low $red_low]"
        append col "[string range $h $green_high $green_high][string range $h $green_low $green_low]"
        append col "[string range $h $blue_high $blue_high][string range $h $blue_low $blue_low]"
    
        set pie_colors($i) $col
    }
    return [array get pie_colors]
}



# ----------------------------------------------------------------------
# Draw a reasonable Pie chart
# ----------------------------------------------------------------------

ad_proc im_dashboard_pie_chart { 
    { -max_entries 7 }
    { -values {} }
    { -red_start 0 }
    { -red_end 255 }
    { -blue_start 255 }
    { -blue_end 0 }
    { -green_start 128 }
    { -green_end 128 }
} {
    Returns a formatted HTML text to display a piechart
    based on Lutz Tautenhahn' "Javascript Diagram Builder", v3.3.
    @param max_entries Determines the max. number of entries
           in the pie chart. It also determines the Y-size of the diagram.
    @param values A list of {name value} pairs to be displayed.
           Values must be numeric (comparable using the "<" operator.      
} {
    # Get a range of suitable colors
    array set pie_colors [im_dashboard_pie_colors \
	       -max_entries $max_entries \
	       -blue_start $blue_start -blue_end $blue_end \
	       -red_start $red_start -red_end $red_end \
	       -green_start $green_start -green_end $green_end \
    ]

    # Sum up the values as a 100% base to calculate percentages
    set pie_sum 0
    foreach value $values {
        set val [lindex $value 1]
        set pie_sum [expr $pie_sum + $val]
    }
    if {0 == $pie_sum} { set pie_sum 0.00001}
    
    # Sort list according to value (2nd element)
    set values [reverse [qsort $values [lambda {s} { lindex $s 1 }]]]
    
    # Format the elements
    set pie_pieces_html ""
    set pie_bars_html ""
    set count 0
    set angle 0
    foreach pie_degree $values {
        if {$count >= $max_entries} { continue }
        set key [lindex $pie_degree 0]
        set val [lindex $pie_degree 1]
        set perc [expr round($val * 1000.0 / $pie_sum) / 10.0]
        set degrees [expr $val * 360.0 / $pie_sum]
        set col $pie_colors($count)
        lappend pie_pieces_html "P\[$count\]=new Pie(100, 100, 0, 80, [expr $angle-1.0], [expr $angle+$degrees+1.0], \"$col\");\n"
        set angle [expr $angle+$degrees]
        set perc_text "${perc}%"
        set pie_text [string range $key 0 12]
    
        lappend pie_bars_html "new Bar(200, [expr 20+$count*20], 250, [expr 35+$count*20], \"$col\", \"$perc_text\", \"#000000\", \"\",  \"void(0)\", \"MouseOver($count)\", \"MouseOut($count)\");\n"
    
        lappend pie_bars_html "new Bar(260, [expr 20+$count*20], 360, [expr 35+$count*20], \"$col\", \"$pie_text\", \"#000000\", \"\",  \"void(0)\", \"MouseOver($count)\", \"MouseOut($count)\");\n"
    
        incr count
    }
    
   
    # Show the "Other"
    if {360 != [expr round($angle)]} {
        set col $pie_colors($count)
        set perc_text "[expr round(10 * (360.0 - $angle)) / 10.0]%"
        set pie_text "Other"
    
        lappend pie_pieces_html "P\[$count\]=new Pie(100, 100, 0, 80, $angle, 360, \"$col\");\n"
    
        lappend pie_bars_html "new Bar(200, [expr 20+$count*20], 250, [expr 35+$count*20], \"$col\", \"$perc_text\", \"#000000\", \"\",  \"void(0)\", \"MouseOver($count)\", \"MouseOut($count)\");\n"
    
        lappend pie_bars_html "new Bar(260, [expr 20+$count*20], 360, [expr 35+$count*20], \"$col\", \"$pie_text\", \"#000000\", \"\",  \"void(0)\", \"MouseOver($count)\", \"MouseOut($count)\");\n"
    }

    set border "border:2px solid blue; "
    set border ""

    return "
        <SCRIPT Language=JavaScript src=/resources/diagram/diagram/diagram.js></SCRIPT> 
        <div style='$border position:relative;top:0px;height:200px;width:500px;'>
        <SCRIPT Language=JavaScript>
        P=new Array();
        document.open();
        _BFont=\"color:\#000000;font-family:Verdana;font-weight:normal;font-size:8pt;line-height:10pt;\";
    
        $pie_pieces_html
        $pie_bars_html
    
        document.close();
        function MouseOver(i) { P\[i\].MoveTo(\"\",\"\",10); }
        function MouseOut(i) { P\[i\].MoveTo(\"\",\"\",0); }
        </SCRIPT>
        </div>
    "

}
    

