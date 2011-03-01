# /packages/intranet-tinytm/www/import-tmx-2.tck
#
# Copyright (C) 2008 ]project-open[
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    Parses a .tmx file in UTF-8 format and inserts all segments
    into TinyTM.
    This page uses an old style "ns_write" technique to write into
    the HTTP session continuosly. This way, the browser will already
    render the first part of the page while the server process is
    still running. This approach is important because the import may
    take several minutes or hours.

    @author frank.bergmann@project-open.com
} {
    action
    return_url
    upload_file
}

# -------------------------------------------------------------
# Default & Security
# -------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-tinytm.Import_TMX "Import TMX"]
set context_bar [im_context_bar $page_title]

set passwd [db_string auth_token "select password from users where user_id = :current_user_id" -default ""]
set auth_token "$current_user_id,$passwd"

# ToDo: Security

# -------------------------------------------------------------------
# Get the file from the user.
# -------------------------------------------------------------------

# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "import-tmx.tcl" -value $tmp_filename
set file_size [file size $tmp_filename]

if { $max_n_bytes && ($file_size > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size: 
    [util_commify_number $max_n_bytes] bytes"
    return 0
}

if {[catch {
    set fl [open $tmp_filename]
    fconfigure $fl -encoding "unicode"
    set content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "Unable to open file $tmp_filename:
    <br><pre>\n$err</pre>"
    return
}

# ------------------------------------------------------------
# Test action - show the contents
# ------------------------------------------------------------

if {"test" == $action} {
    ns_write "
	[im_header]
	[im_navbar]
	<h1>Sample Content</h1><p>
	This page shows the first 1000 characters of your TMX file
	to allow you to check the character encoding.<p>
	You should see something like:<p>&nbsp;</p>
<pre>
	?xml version=\"1.0\" ?&gt;
	&lt;!DOCTYPE tmx SYSTEM \"tmx11.dtd\"&gt;
	&lt;tmx version=\"version 1.1\"&gt;
	&lt;header
	  creationtool=\"TMXtract 1.00 07-04-2008\"
	  adminlang=\"EN-US\"
	  srclang=\"EN-GB\"
	&gt;
	&lt;/header&gt;
	&lt;body&gt;
	...
</pre>
	<p>&nbsp;</p>
	<h1>Actual TMX Contents</h1>
    "

#    ns_write $content

    set content [string range $content 1 1000]
    ns_write "<pre>[ns_quotehtml $content]</pre>\n"
    ns_write "\n</ul><p>\n<A HREF=$return_url>Return to last page</A>\n"
    ns_write [im_footer]
    ad_script_abort

}

# ------------------------------------------------------------
# Render Page Header
# ------------------------------------------------------------

ad_return_top_of_page "
	[im_header]
	[im_navbar]
	<table cellspacing=0 cellpadding=0 border=0>
	<tr valign=top>
	  <td width='50%'><!-- Filters --></td>
	  <td align=center width='50%'>
		<table cellspacing=2 width='90%'>
		<tr>
		  <td>&nbsp;</td>
		</tr>
		</table>
	  </td>
	</tr>
	</table>
	<table border=0 cellspacing=1 cellpadding=1>

	<ul>
"


# -------------------------------------------------------------------
# Parse the entire XML document
# -------------------------------------------------------------------

ns_write "<li>Parsing the TMX document... \n"
set doc [dom parse $content]
set root_node [$doc documentElement]
ns_write "finished</li>\n"


# -------------------------------------------------------------------
# Get the source language from the header
# -------------------------------------------------------------------

# Start parsing with the "header" tag.
set header_node [$root_node selectNodes "header"]

set source_lang [string tolower [$header_node getAttribute srclang ""]]
if {"" == $source_lang} { ad_return_complaint 1 "Didn't find 'srclang' attribute of tag 'header'" }


# -------------------------------------------------------------------
# Insert the segments into TinyTM
# -------------------------------------------------------------------

# Start parsing with the "body" tag.
set body_node [$root_node selectNodes "body"]


# The "body" tag has a lot "translation unit" (tu) nodes below.
foreach tu_node [$body_node childNodes] {

#    ns_write "<li>TU: [$tu_node nodeName]</li>\n\n"


    # The properties of the current TU
    set property_node [$tu_node selectNodes "prop"]

    # Every TU has one "prop" = property node and two "tuv" nodes
    set source_segment ""
    set target_segment ""
    set target_lang ""
    foreach tuv_node [$tu_node childNodes] {
	# ns_write "<li>TU Child: [$tuv_node nodeName]</li>\n\n"
	case [$tuv_node nodeName] {
	    prop {
		
	    }
	    tuv {
		set tuv_lang [string tolower [$tuv_node getAttribute lang]]
		set seg_node [$tuv_node firstChild]
		set text_node [$seg_node firstChild]
		set segment [$text_node data]
		if {$source_lang == $tuv_lang} {
		    set source_segment $segment
		} else {
		    set target_segment $segment
		    set target_lang $tuv_lang
		}
	    }
	    default { 
		ad_return_complaint 1 "Found an unknown node below a TU: '[$tuv_node nodeName]'" 
		ad_script_abort
	    }
	}
    }

    # At this point we have {source|target}_{lang|segment} defined.
    # Let's insert into the TM:
    ns_write "<li>TU: $source_lang-$tuv_lang: $source_segment-$target_segment</li>\n"

    set tag_string ""

    set sql "
	SELECT tinytm_new_segment(
		:auth_token, 
		:source_lang, :target_lang,
		:source_segment, :target_segment
	)
    "
    if {[catch {
	db_string tinytm_insert $sql
    } err_msg]} {

	ns_write "\n</ul>\n"
	ns_write "<font color=red>\n"
	ns_write "<pre>Error:\n$err_msg</pre>"
	ns_write "</font>\n"
	ns_write [im_footer]
	ad_script_abort
    }
}

# ------------------------------------------------------------
# Render Report Footer

ns_write "\n</ul><p>\n<A HREF=$return_url>Return to last page</A>\n"
ns_write [im_footer]

