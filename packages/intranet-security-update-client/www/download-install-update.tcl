ad_page_contract {
    Loads a .tgz update

    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { url ""}
    { debug 1 }
}


# -------------------------------------------------------
# Defaults & Security
# -------------------------------------------------------

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]">
    return
}

# By default load the file into the ~/ directory.

# 091102 fraber: Changes from Maurizio
global tcl_platform
set platform [lindex $tcl_platform(platform) 0]
switch $platform {
    windows {
	set file_path "."
    }
    unix {
	set file_path [acs_root_dir]
    }
}


# The file name is the last piece of the URL
set url_pieces [split $url "/"]
set file_name [lindex $url_pieces [expr [llength $url_pieces]-1]]

set file_pieces [split $file_name "."]
set file_ext [string tolower [lindex $file_pieces [expr [llength $file_pieces]-1]]]
set filename "$file_path/$file_name"

if {"tgz" != $file_ext} {
    ad_return_complaint 1 "<b>Invalid File Extension</b><br>We expect an extension '.tgz', but found extension '.$file_ext."
    ad_script_abort
}

set page_title "Load Updates"
set context_bar [im_context_bar $page_title]

set system_id [im_system_id]
set file_url [export_vars -base $url {system_id}]

# -------------------------------------------------------
# Get the file
# -------------------------------------------------------

# Write out HTTP header
im_report_write_http_headers -output_format html

# Add the HTML select box to the head of the page
ns_write [im_header]
ns_write [im_navbar]
ns_write "<ul>\n"

# delete the file if it was there already
if {[catch {
    if {[file isfile $filename] && [file exists $filename]} {
	ns_write "<li>Found existing '$filename', deleting it.\n"
	file delete -force $filename
    }
} err_msg]} {
    ns_write "
	<li><b>Error deleting file '$filename'</b>:<br>
	Please check your url or your file system.<br>
	<pre>[ad_quotehtml $err_msg]</pre>
    "
    ns_write "</ul>[im_footer]\n"
    ad_script_abort

}

ns_write "
	<li>Downloading <a href=\"$url\">$url</a><br>
	into $filename<br><br>
	using command: <pre></pre>exec /usr/bin/wget -q -O $filename $file_url<br>
	<li>This may take several seconds or minutes, depending on your Network connection, so please be patient...
"

set file_size 0
if {[catch {

    # Use wget for HTTP download, allowing to follow redirects in SourceForge.
    exec /usr/bin/wget -q -O $filename $file_url

} err_msg] } {

    ns_write "
	<li><b>Unable to load url '$file_url' into file '$filename'</b>:<br>
	Commend to execute:<br><pre>exec /usr/bin/wget -q -O $filename $file_url</pre><br>
	Error message:<br><pre>[ad_quotehtml $err_msg]</pre>
    "
    ns_write "</ul>[im_footer]\n"
    ad_script_abort
}	

ns_write "<li>Download complete.<pre>$err_msg</pre>\n"


# -------------------------------------------------------
# Check if the update file is a valid TGZ
# -------------------------------------------------------

set gzip_cmd [parameter::get -package_id [im_package_core_id] -parameter "GzipCmd" -default "/usr/bin/gzip"]
if {[catch { exec $gzip_cmd --test $filename } gzip_err]} {
    ns_write "
	<li><b>Invalid format of '$filename'</b>:<br>
	The file '$filename' is not a valid 'gzip' file.<br>
	Here is the original error message:
	<pre>[ad_quotehtml $gzip_err]</pre>
    "
    ns_write "</ul>[im_footer]\n"
    ad_script_abort
} else {
    ns_write "<li>Found a valid checksum of file '$filename'.\n"
}



# -------------------------------------------------------
# Check if the update file starts with "packages/"
# -------------------------------------------------------

set tar_cmd [parameter::get -package_id [im_package_core_id] -parameter "TarCmd" -default "/bin/tar"]
set file_list ""
if {[catch { set file_list [exec $tar_cmd tzf $filename] } tar_err]} {
    ns_write "
	<li><b>Error unpacking '$filename'</b>:<br>
	The file '$filename' is not a valid 'tgz' file.<br>
	Here is the original error message:
	<pre>[ad_quotehtml $tar_err]</pre>
    "
    ns_write "</ul>[im_footer]\n"
    ad_script_abort
} else {
    ns_write "<li>Found a valid '.tzg' file.\n"
}

# -------------------------------------------------------
# Check that the file_list has atleast 5 entries.
# -------------------------------------------------------

if {[llength $file_list] < 5} {
    ns_write "
	<li><b>Error with contained files.</b>:<br>
	The update contains less then 5 files, which is no considered
	a valid update file.
    "
    ns_write "</ul>[im_footer]\n"
    ad_script_abort
} else {
    ns_write "<li>Found a valid update file with [llength $file_list] included files.\n"
}


# -------------------------------------------------------
# Check if all contained files start with "packages/".
# -------------------------------------------------------

set invalid_file ""
foreach f $file_list {
    set first_path [lindex [split $f "/"] 0]

    # Skip known README and CHANGELOG files
    if {[regexp -nocase {readme} $first_path match]} { continue }
    if {[regexp -nocase {changelog} $first_path match]} { continue }
    if {[regexp -nocase {license} $first_path match]} { continue }
    if {"packages" != $first_path} { 
	set invalid_file $f
    }
}

if {"" != $invalid_file} {
    ns_write "
	<li><b>Error unpacking '$filename'</b>:<br>
	There is at least one file in the update
	that does not start with the path 'package/':
 	<br><pre>$invalid_file</pre><br>
	<b>No actions taken</b>.
    "
    ns_write "</ul>[im_footer]\n"
    ad_script_abort
} else {
    ns_write "<li>Found that all included files have the correct path.\n"
}


# -------------------------------------------------------
# At this point we know that we've got a valid update
# that we can safely extract using a TAR command.
# -------------------------------------------------------


ns_write "<li>Extracting files into file system...\n"


set tar_output ""
if {[catch { set tar_output [exec $tar_cmd --directory $file_path -x -z -f $filename] } tar_err]} {
    ns_write "
	<li><b>Error unpacking '$filename'</b>:<br>
	Here is the original error message:
	<pre>[ad_quotehtml $tar_err]</pre>
    "
    ns_write "</ul>[im_footer]\n"
    ad_script_abort
} else {
    ns_write "
	<li>Successfully updated your system.
    "
    ns_write "<li>Please <a href='/acs-admin/server-restart'>restart your server</a> now."
}


ns_write "</ul>\n"
ns_write [im_footer]

