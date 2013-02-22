# /admin/monitoring/registered-procs.tcl

ad_page_contract {
    Displays a list of registered procedures.

    @author Jon Salz (jsalz@mit.edu)
    @cvs-id $Id: registered-procs.tcl,v 1.1.1.2 2006/08/24 14:41:39 alessandrol Exp $
} {
    match_method:optional
    match_path:optional
}

if { ![info exists match_method] } {
    set match_method "GET"
}
if { ![info exists match_path] || $match_path == "" || $match_path == "(any)" } {
    set match_path "(any)"
} else {
    if { ![regexp {^/} $match_path] } {
    set match_path "/$match_path"
    }
}

set title "Registered Procedures"
set context [list "$title"]

set page_content "

<form>

<h2>Registered Procedures on [ad_system_name]</h2>



<font color=red>NOTE: In ACS 4.x, you should probably be using .vuh files instead of registered procs!</font>
<p>

Showing <select name=match_method onChange=\"form.submit()\">
[ad_generic_optionlist [list "all" "GET" "HEAD" "POST"] [list "" "GET" "HEAD" "POST"] $match_method]
</select>

filters matching path:

<input name=match_path value=\"$match_path\"> <input type=submit value=\"Show\">
[ad_decode [expr { $match_path == "(any)" }] 0 "<input type=button onClick=\"form.match_path.value='(any)';form.submit()\" value=\"Show All\">" ""]
<table>
<tr>
<th align=left bgcolor=#C0C0C0>Method</th>
<th align=left bgcolor=#C0C0C0>Path</th>
<th align=left bgcolor=#C0C0C0>Proc</th>
<th align=left bgcolor=#C0C0C0>Defined in File</th>
<th align=left bgcolor=#C0C0C0>Args</th>
<th align=center bgcolor=#C0C0C0>Inherit?</th>
<th align=center bgcolor=#C0C0C0>Debug?</th>
</tr>
"

if { $match_method == "" } {
    set match_method [list GET HEAD POST]
}

set output ""

set counter 0
set bgcolors { white #E0E0E0 }
foreach meth $match_method {
    foreach f [nsv_get rp_registered_procs "$meth"] {
    set bgcolor [lindex $bgcolors [expr { $counter % [llength $bgcolors] }]]
    incr counter
        
    set method [lindex $f 0]
    set path [lindex $f 1]
    set proc [lindex $f 2]
    set args [lindex $f 3]
    if { $args == "" } {
        set args "&nbsp;"
    }
    set debug [ad_decode [lindex $f 4] "t" "Yes" "No"]
    set inherit [ad_decode [lindex $f 5] "f" "Yes" "No"]
    set description [lindex $f 6]
    set file [file tail [lindex $f 7]]
    if { [empty_string_p $file] } {
        set file "&nbsp;"
    }
    if { $match_path == "(any)" || \
        [string match $path $match_path] || \
        ($inherit == "Yes" && [string match "$path/*" $match_path]) } {
        append output "<tr>"
        foreach name { method path proc file args inherit debug } {
        append output "<td bgcolor=$bgcolor>[set $name]</td>"
        }
        append output "</tr>\n"
    }
    }
}

append page_content "$output</table>


"

# doc_return 200 text/html $page_content