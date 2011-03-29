# /packages/intranet-ganttproject/www/test/index.tcl
#
# Copyright (C) 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Execute all tests and show a result
    @author frank.bergmann@project-open.com
} {
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------


# ---------------------------------------------------------------
# Write out HTTP Header
# ---------------------------------------------------------------

set content_type "text/html"
set http_encoding "utf-8"
append content_type "; charset=$http_encoding"
set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"
util_WriteWithExtraOutputHeaders $all_the_headers
ns_startcontent -type $content_type



# ---------------------------------------------------------------
# Start Tests
# ---------------------------------------------------------------

set test_list {
    { single-task "" }
}

set params [list]
foreach test_case $test_list {
    set test [lindex $test_case 0]
    set note [lindex $test_case 1]
    ns_write "<li>$test: Starting: $note"
    if {[catch {
	set result [ad_parse_template -params $params "/packages/intranet-ganttproject/www/test/$test"]
    } err_msg]} {
	ns_write "<li>Error in test '$test': $err_msg"
    }
    ns_write "<li>$test: Finished"
}

