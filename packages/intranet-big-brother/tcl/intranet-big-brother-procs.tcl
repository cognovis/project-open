# /tcl/intranet-big-brother-procs.tcl

ad_library {
    Interface to the Big Brother System Monitoring system.
    @author frank.bergmann@project-open.com
    @creation-date  27 June 2003
    
    This module basically parses a BigBrother V1.8b report and
    reformats the report suitable as a component for the ]po[
    home page
}


ad_proc im_big_brother_component { user_id } {
    Creates a table showing the status of the Big Brother
    System Monitoring tool
} {
    set bb_html ""

    set package_key "intranet-big-brother"
    set package_id [db_string package_id "select package_id from apm_packages where package_key=:package_key" -default 0]
    set bb_url [parameter::get -package_id $package_id -parameter "BigBrotherUrl" -default ""]

    set bb_content ""
    if { [catch {
	set bb_content [exec /usr/bin/wget -q -O - $bb_url]
    } err_msg] } {
	append bb_html "<pre>/usr/bin/wget -q -O - $bb_url\n$err_msg</pre>\n"
    }
    set bb_lines [split $bb_content "\n"]

    # -------------------------------------------------------
    # Extract the overall status from the BB file
    # We are looking for this line:
    # <TITLE>green : Big Brother ... </TITLE>
    set bb_status "unknown"
    foreach bb_line $bb_lines {
	if {[regexp -nocase {<title>([a-zA-Z]*)} $bb_line match status]} {
	    set bb_status $status
	}
    }

    if {"" == $bb_content} {
	set bb_status "$bb_url not found"
    }
    append bb_html "
<ul>
<li><A href=$bb_url>Big Brother - $bb_status</A>
</ul>
<table>\n"

    # -------------------------------------------------------
    # Extract valid BB <tr>-lines
    # Valid BB lines start with "<TR><TD ALIGN=CENTER NOWRAP>"
    # and end with "</TR>"
    set bb_body ""
    set in_line 0
    foreach bb_line $bb_lines {

	# Determine if we are withing a reasonable BB <tr>....</tr> line
	ns_log Notice "im_big_brother_component: line=$bb_line"
	if {[regexp {^<TR>} $bb_line match]} { set in_line 1 }
	if {[regexp {^</TR>} $bb_line match]} { set in_line 0 }

	# Remove font tags such as this one:
	# <FONT SIZE=+1 COLOR="#FFFFCC" FACE="Tahoma, Arial, Helvetica">ehrms</FONT></TD>
	if {[regexp -nocase {^<font .*>([0-9a-zA-Z_]*)</font></td>} $bb_line match server]} {
	    set bb_line "$server</td>"
	}


	# Fix the URL of the detailed information
	# <TD ALIGN=CENTER><A HREF="/bb/html/berlin.procs.html">
	if {[regexp -nocase {^<td[^>]*><a href=\"([^"]*)\"} $bb_line match url]} {

	    # Url looks like: /bb/html/berlin.procs.html
	    # We have to extract only "berlin.procs.html"
	    set url_parts [split $url "/"]
	    set url_part_len [llength $url_parts]
	    set url_part_len [expr $url_part_len - 1]
	    set url [lindex $url_parts $url_part_len]

	    set bb_line "<td align=center><a href=\"${bb_url}html/$url\">"
	}


	# Remove size information
	# <IMG SRC="/bb/gifs/green.gif" ALT="conn:green" HEIGHT="32" WIDTH="32" BORDER=0></A></TD>
	if {[regexp -nocase {^<img src=\"([^"]*)\" ALT=\"([^"]*)\"[^>]*></a></td>} $bb_line match url alt]} {

	    # Url looks like: /bb/gifs/green.gif
	    # We have to extract only "green.gif"
	    set url_parts [split $url "/"]
	    set url_part_len [llength $url_parts]
	    set url_part_len [expr $url_part_len - 1]
	    set url [lindex $url_parts $url_part_len]

	    set bb_line "<img src=\"/intranet-big-brother/images/$url\" alt=\"$alt\" width=16 height=16 border=0></a></td>"
	}

	if {$in_line} {
	    append bb_body "$bb_line\n"
	}
    }

    append bb_html "
$bb_body
</table>
"
    
    return [im_table_with_title "[_ intranet-big-brother.Big_Brother_Status]" $bb_html]
}
