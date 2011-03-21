# /packages/intranet-exchange-rate/www/get-exchange-rates.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2008-08-04
    @cvs-id $Id: get-exchange-rates.tcl,v 1.6 2011/03/08 18:16:10 po34demo Exp $
} {
    { return_url "/intranet-exchange-rate/index" }
}

set today [lindex [split [ns_localsqltimestamp] " "] 0]
set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]">
    return
}

set page_title [lang::message::lookup "" intranet-security-update-client.Get_ASUS_Exchange_Rates "Get ASUS Exchange Rates"]
set context_bar [im_context_bar $page_title]
set context [list [list "../developer" "Developer's Administration"] $page_title]

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

set currency_update_url [im_security_update_get_currency_update_url]

# ------------------------------------------------------------
# Return the HTTP header etc.


# Write out HTTP header
im_report_write_http_headers -output_format html



ns_write "
        [im_header]
        [im_navbar]

	<h2>Getting data</h2>
	<ul>
"

# ------------------------------------------------------------
# Fetch the update.xml file from the remote server
#

ns_write "<li>Getting exchange rates XML file from '$currency_update_url' ...\n"

set update_xml ""
if { [catch {
	set update_xml [ns_httpget $currency_update_url]
} errmsg] } {
    ad_return_complaint 1 "Error while accessing the URL '$currency_update_url'.<br>
	Please check your URL. The following error was returned: <br>
	<blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>"
    return
}

if {"" == $update_xml} {
    ad_return_complaint 1 "Found an empty XML file accessing the URL '$currency_update_url'.<br>
	This means that your server(!) was not able to access the URL.<br>
	Please check the the Internet and firewall configuration of your
	server and verify that the 'nsd' (Linux) or 'nsd4' (Windows) 
	process has access to the URL.<br>"
    return
}	

ns_write "Success</li>\n"


# ------------------------------------------------------------
# Check whether it's a HTML or an XML
#
# The correct XML outplut will look like this:
# <asus_reply>
# <error>ok</error>

if {![regexp {<([^>]*)>\s*<([^>]*)>} $update_xml match tag1 tag2]} {
    ns_write "
	<li>
		<font color=red>
		Error while retreiving update information from
		URL '$currency_update_url'.<br>
		The retreived files doesn't seem to be a XML or HTML file:<br>
		<pre>$update_xml</pre>
		</font>
	</li>
    "
    set update_xml ""
}

if {[string tolower $tag1] == "html" || [string tolower $tag2] == "html"} {
    ns_write "
	<li>
		<font color=red>
		Error while retreiving update information from  URL<br>
		'$currency_update_url'.<br>
		The retreived result seems to be a HTML document and not an XML document.<br>
		Please check the URL above and/or send an error report to 
		<a href=\"mailto:support@project-open.com\">support@project-open.com</a>.
		<br>&nbsp;</br>
		Here is what the server returned:
		<br>&nbsp;</br>
		<pre>$update_xml</pre>
		</font>
	</li>
    "
    set update_xml ""
}


# ------------------------------------------------------------
# Enabled Currencies
# ------------------------------------------------------------

set enabled_currencies_sql "
	select	iso
	from	currency_codes
	where	supported_p = 't'
"
db_foreach encur $enabled_currencies_sql {
    set enabled_currencies_hash($iso) 1 
}

# ------------------------------------------------------------
# Parse the XML file and generate the HTML table
#

set html [im_security_update_update_currencies -update_xml $update_xml]
ns_write $html
ns_flush

ns_write "<li>Extrapolating exchange rates:</li>\n"


set ttt {
set enabled_currencies [db_list enabled_currencies "select iso from currency_codes where supported_p = 't'"]
foreach cur $enabled_currencies {

    ns_write "<li>Extrapolating exchange rates for '$cur' ... </li>\n"
    set success "Success"
    if {[catch {
	im_exec_dml invalidate "im_exchange_rate_fill_holes(:cur)"
    } err_msg]} {
	set success "<pre>$err_msg</pre>"
    }
    ns_write "$success</li>\n"
}
}

ns_write "<li>Finished.</li>\n"
ns_write "</ul>\n"
ns_write "<p>&nbsp;</p>\n"

ns_write "<ul><li><a href=\"$return_url\">Return to previous page</a></li></ul>\n"

ns_write [im_footer]
