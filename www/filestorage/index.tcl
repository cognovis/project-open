 # /www/intranet/filestorage/index.tcl

ad_page_contract { 
    Show the content a specific subdirectory

    @param letter criteria for im_first_letter_default_to_a(ug.group_name)
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @author mbryzek@arsdigita.com
    @cvs-id index.tcl,v 3.24.2.9 2000/09/22 01:38:44 kevin Exp
} {
    { group_id:integer  }
}

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set page_title "File Tree"
set context_bar [ad_context_bar $page_title]
set page_focus ""
set path "/home/sls/mysls/transpose/2003_0012/"
set path "/home/sls/projects/projects_M_Z/transpose/left_brain/02096162/"


set trados_files_csv "/home/sls/projects/projects_M_Z/transpose/left_brain/02096162/20030613_prescient_helpdesk_without_glossary_4.csv"

set trados_files_content [exec /bin/cat $trados_files_csv]
set trados_files [split $trados_files_content "\n"]
set trados_files_len [llength $trados_files]
set trados_header [lindex $trados_files 1]
set trados_headers [split $trados_header ";"]
for {set i 2} {$i < $trados_files_len} {incr i} {
    set trados_line [lindex $trados_files $i]
    ns_log Notice "$i: $trados_line"

    if {$i > 10} { break }
    set trados_fields [split $trados_line ";"]

}



set page_body "
<table bgcolor=white cellspacing=0 border=0 cellpadding=0>
<tr> 
  <td class=rowtitle align=center>Name&nbsp;</td>
  <td class=rowtitle align=center>Upl.<BR>Downl.&nbsp;</td>
<!--  <td class=rowtitle align=center>Man<BR>age&nbsp;</td> -->
<!--  <td class=rowtitle align=center>Refers<BR>to&nbsp;</td> -->
  <td class=rowtitle align=center>Words&nbsp;</td>
<!--  <td class=rowtitle align=center>Status&nbsp;</td> -->
  <td class=rowtitle align=center>Size&nbsp;</td>
  <td class=rowtitle align=center>Modified&nbsp;</td>
  <td class=rowtitle align=center>Owner&nbsp;</td>
</tr>

<!-- Create a first 'folder' with the project name -->
<tr> 
  <td>
    <table cellpadding=0 cellspacing=0 border=0><tr>
      <td><img border=0 src=/images/exp-folder.gif width=19 height=16></td>
      <td>&nbsp;$page_title</td>
    </tr></table>
  </td>
  <td> 
  </td>
<!--  <td>-</td> -->
<!--  <td></td> -->
  <td></td>
<!--  <td>Source</td> -->
  <td></td>
  <td></td>
  <td></td>
</tr>
"

if { [catch {
    set file_list [exec /usr/bin/find $path]
} err_msg] } {
    # Probably some permission errors
    set page_body "
	<H3>Permission Error</H3>
	<P>There was a permission error reading on the Unix
	file system at: <TT>$path</TT>. Please contact your webmaster (below)
        to resolve the issue.</P>
        &nbsp;
"
    doc_return  200 text/html [im_return_template]
}

set org_paths [split $path "/"]
set org_paths_len [llength $org_paths]
set start_index [expr $org_paths_len - 1]

# Get the sorted list of files in the directory
set files [lsort [split $file_list "\n"]]

foreach file $files {
    set file_paths [split $file "/"]
    set file_paths_len [llength $file_paths]
    set body_index [expr $file_paths_len - 1]
    set file_body [lindex $file_paths $body_index]
    set file_type [file type $file]
    set file_size [file size $file]
    set file_modified [file mtime $file]
    set file_extension [lindex [split $file_body "."] 1]
    if {[string equal $file $path]} { 
	# Skip the path itself
	continue 
    }

    # Determine how many "tabs" the file should be indented
    set spacer ""
    for {set i [expr $start_index + 1]} {$i < $file_paths_len} {incr i} {
	append spacer "<IMG SRC='/images/exp-line.gif' width=19 height=16>"
    }

    # determine the part of the filename _after_ the base path
    set end_path ""
    for {set i $start_index} {$i < $file_paths_len} {incr i} {
	append end_path [lindex $file_paths $i]
	if {$i < [expr $file_paths_len - 1]} { append end_path "/" }
    }

    switch $file_type {
	file {
	    # Choose a suitable icon
	    set icon "/images/exp-unknown.gif"
	    switch $file_extension {
		"xls" { 
		    set icon "/images/exp-excel.gif" 
		}
		"doc" { 
		    set icon "/images/exp-word.gif" 
		}
		"txt" { 
		    set icon "/images/exp-text.gif" 
		}
		default {
		    ns_log Notice "unknown file_extension: '$file_extension'"
		}
	    }
	    
	    # Build a <tr>..</tr> line for the file
	    set line "
<tr> 
  <td>
    <table cellpadding=0 cellspacing=0 border=0><tr>
    <td>$spacer<img border=0 src='$icon' width='19' height='16'></td>
    <td>&nbsp;$file_body</td>
    </tr></table>
  </td>
  <td><A href='/intranet/filestorage/download?file_name=$end_path'><img src='/images/save.gif' border=0 width=14 height=15 alt='Download file to your local disk'></A></td>
<!--  <td>-</td> -->
<!--  <td></td> -->
  <td>1234</td>
<!--  <td>Source</td> -->
  <td>$file_size</td>
  <td>$file_modified</td>
  <td>ijimenez</td>
</tr>
"	}


	directory {
	    set line "
<tr>
  <td valign=top>
    <table cellpadding=0 cellspacing=0 border=0><tr>
    <td>$spacer<img border=0 src=/images/exp-minus.gif width=19 height=16'><img border=0 src=/images/exp-folder.gif width=19 height=16></td>
    <td>&nbsp;$file_body</td>
    </tr></table>
  </td>
  <td><A href='/intranet/filestorage/upload?folder=$end_path&return_url=/intranet/projects/view'><img src='/images/open.gif' border=0 width=16 height=15 alt='Upload a new file'></A></td>
<!--  <td align=center>
    <img src='/images/open.gif' width='16' height='15' 
    alt='Mark the folder as &quot;Open&quot;'>
  </td>
-->
<!--  <td></td> -->
  <td align=right><!-- Words--></td>
<!--  <td>Closed</td> -->
  <td></td>
  <td></td>
  <td>ijimenez</td>
</tr>
"	}
	default { set line "unknown filetype: '$file_type'" }
    }

    append page_body "$line\n"
}

append page_body "
</table>

"

doc_return  200 text/html [im_return_template]

