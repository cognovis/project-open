# /packages/intrane-filestorage/www/erase-file.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Show the content a specific subdirectory

    @param folder_type 
    @param project_id
    @param file_name
    @param return_url

    @author pvilarmau@hotmail.com
    @author santitrenchs@santitrenchs.com
    @author frank.bergmann@project-open.com
} {
    { id_file:array,optional }
    { id_row:array,optional }
    {folder_type ""}
    group_id:notnull
    return_url:notnull
}

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set page_title "File Tree Competitiveness"
set context_bar [ad_context_bar_ws $page_title]
set page_focus ""

set current_user_id [ad_maybe_redirect_for_registration]

set start_path $return_url
set return_url [im_url_with_query]
set query "select g.group_name as project_name from user_groups g where group_id=$group_id"


if { ![db_0or1row projects_info_query $query] } {
    ad_return_complaint 1 "Can't find the project with group id of $group_id"
    return
}



	set file_type ""

	foreach {clau valor} [array get id_row] {
			if { [catch {
	    	set file_type [file type $id_file($clau)]
			} err_msg] } { }
			if { [string compare $file_type "directory"] == 0 } {    	
    		append file_name $id_file($clau)
    		append nom "<br>Directory to delete: "
    		append nom $valor
    	} else {
    		append file_name $id_file($clau)
    		append nom "<br>File to delete: "
    		append nom $valor
    	}
    		
	}



set page_content "$nom <br><br>"

append page_content "
<table>
<tr>
<td>
Are you sure to delete this file?
</td>
</tr>
</table>
<table>
  <tr>
   <td>
    <form method='post' action='erase-file-2.tcl'>
       <input type='submit' value='Erase'><input type='hidden' name=group_id value='$group_id'><input type='hidden' name=folder_type value='$folder_type'><input type='hidden' name=file_name value='$file_name'>
       <input type='hidden' name=return_url value='$return_url'><input type='hidden' name=start_path value='$start_path'>"   
    
    set i 0
    
   	foreach {clau valor} [array get id_row] {
	   append page_content "<input type=\"hidden\" name=\"id_file.$i\" value=\"$id_file($clau)\">"
	   incr i
		}
       
     append page_content "  
    </form>
   </td>
   <td>
     <form method='post' action='$start_path'>
       <input type='submit' value='Cancel'>
     </form>
   </td>
 </tr>
</table>

</td>
</tr>
</table>
<br>
"

db_release_unused_handles


set page_title "Delete"
doc_return  200 text/html [im_return_template]



