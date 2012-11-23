# /packages/intranet-sencha/www/action.tcl
#
# Copyright (C) 2003-2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Receive "save" actions from Sencha forms
    @author frank.bergmann@project-open.com
} {
    { first "" }
    { last "" }
}

set user_id [ad_maybe_redirect_for_registration]



set debug "\n"
append debug "method: [ns_conn method]\n"

set header_vars [ns_conn headers]
foreach var [ad_ns_set_keys $header_vars] {
    set value [ns_set get $header_vars $var]
    append debug "header: $var=$value\n"
}

set form_vars [ns_conn form]
foreach var [ad_ns_set_keys $form_vars] {
    set value [ns_set get $form_vars $var]
    append debug "form: $var=$value\n"
}

append debug "content: [ns_conn content]\n"

ns_log Notice "/intranet-sencha/save-form: first=$first, last=$last, uid=$user_id, debug=$debug"

regsub -all {\n} $debug {<br>} debug


doc_return 200 "text/plain" "
    {
	\"success\": true,
	\"msg\": \"Save-form successful: $debug\"
    }
"

