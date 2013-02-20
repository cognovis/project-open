# /admin/monitoring/watchdog/index.tcl

ad_page_contract {
    @cvs-id $Id: index.tcl,v 1.1.1.2 2006/08/24 14:41:44 alessandrol Exp $
} {
    kbytes:integer,optional
    num_minutes:integer,optional
}

if { [info exists num_minutes] && ![empty_string_p $num_minutes] } {
    set kbytes ""
    set bytes ""
} else {
    set num_minutes ""
    if { ![info exists kbytes] || [empty_string_p $kbytes] } {
    set kbytes 200
    }
    set bytes [expr $kbytes * 1000]
}

set title "WatchDog"
set context [list "$title"]

set whole_page "

<h2>WatchDog</h2>


<FORM ACTION=index>    
Errors from the last <INPUT NAME=kbytes SIZE=4 value=\"$kbytes\"> Kbytes of error log. 
<INPUT TYPE=SUBMIT VALUE=\"Search again\">
</FORM>

<FORM ACTION=index>
Errors from the last <INPUT NAME=num_minutes SIZE=4 value=\"$num_minutes\"> minutes of error log. <INPUT TYPE=SUBMIT VALUE=\"Search again\">
</FORM>

<PRE>
[ns_quotehtml [wd_errors -external_parser_p 1 -num_minutes "$num_minutes" -num_bytes "$bytes"]]
</PRE>


"