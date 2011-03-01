# /packages/intranet-mail-import/www/index.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Show the list of current task and allow the project
    manager to create new tasks.

    @author frank.bergmann@project-open.com
    @creation-date Nov 2003
} {
    { bread_crum_path "" }
}

set user_id [ad_maybe_redirect_for_registration]
set return_url "/intranet-filestorage/"
set current_url_without_vars [ns_conn url]


# im_mail_import::scan_mails

im_mail_import::process_mails -mail_dir [im_mail_import::mail_dir]


set page_body ""


if {0} {

    set page_body [im_filestorage_home_component $user_id]
    db_release_unused_handles
    return

}

if {0} {

    set html "<pre>\n"
    set header_vars [ns_conn headers]
    foreach var [ad_ns_set_keys $header_vars] {
	set value [ns_set get $header_vars $var]
	
	append html "header:	$var	= $value\n"
    }
    set form_vars [ns_conn form]
    if {"" != $form_vars} {
	foreach var [ad_ns_set_keys $form_vars] {
	    set value [ns_set get $form_vars $var]
	    
	    append html "form:	$var	= $value\n"
	}
    }
    append html "\nquery: [ns_conn query]"
    append html "</pre>\n"
    append html "
<form action=index method=POST>
<input type=text name=erter value=ertz>
<input type=submit name=adsf value=sdfg>
</form>
"
    
    doc_return  200 text/html $html
    db_release_unused_handles
    
}

