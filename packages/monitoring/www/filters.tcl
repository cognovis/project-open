# /www/admin/monitoring/filters.tcl

ad_page_contract {
    Displays a list of filter procs present on the web server.

    @author        Jon Salz <jsalz@mit.edu>
    @cvs-id $Id: filters.tcl,v 1.1.1.2 2006/08/24 14:41:39 alessandrol Exp $
} {
    {match_method "GET"}
    {match_path "(any)"}
}

if { $match_path == "(any)" } {
} else {
    if { ![regexp {^/} $match_path] } {
	set match_path "/$match_path"
    }
}


set title "Filters"
set context [list "$title"]



set page_content "

<form>

<h2>Filters on [ad_system_name]</h2>



Showing <select name=match_method onChange=\"form.submit()\">
[ad_generic_optionlist [list "all" "GET" "HEAD" "POST"] [list "" "GET" "HEAD" "POST"] $match_method]
</select>

filters matching path:

<input name=match_path value=\"$match_path\"> <input type=submit value=\"Show\">
[ad_decode [expr { $match_path == "(any)" }] 0 "<input type=button onClick=\"form.match_path.value='(any)';form.submit()\" value=\"Show All\">" ""]
<table>
<tr>
<th align=left bgcolor=#C0C0C0>Priority</th>
<th align=left bgcolor=#C0C0C0>Kind</th>
<th align=left bgcolor=#C0C0C0>Method</th>
<th align=left bgcolor=#C0C0C0>Path</th>
<th align=left bgcolor=#C0C0C0>Proc</th>
<th align=left bgcolor=#C0C0C0>Defined in File</th>
<th align=left bgcolor=#C0C0C0>Args</th>
<th align=center bgcolor=#C0C0C0>Debug?</th>
<th align=center bgcolor=#C0C0C0>Crit.?</th>
</tr>
"


if { [empty_string_p $match_method] } {
    set match_method [list GET HEAD POST]
}

set counter 0
set bgcolors { white #E0E0E0 }
foreach f [nsv_get rp_filters "."] {
    util_unlist $f priority kind method path \
            proc args debug critical description script

    if { ![string match "*$method*" $match_method] } {
        continue
    }

    set bgcolor [lindex $bgcolors [expr { $counter % [llength $bgcolors] }]]
    incr counter
    
    if { $args == "" } {
        set args "&nbsp;"
    }
    set debug [ad_decode [lindex $f 6] "t" "Yes" "No"]
    set critical [ad_decode [lindex $f 7] "t" "Yes" "No"]
    set description [lindex $f 8]
    set file [file tail [lindex $f 9]]
    if { ($match_path != "(any)" && ![string match $path $match_path]) } {
        continue
    }
    append page_content "<tr>"
    foreach name { priority kind method path proc file args debug critical } {
        append page_content "<td bgcolor=$bgcolor>[set $name]</td>"
    }
    append page_content "</tr>\n"
}

append page_content "</table>

"

# doc_return 200 text/html $page_content
