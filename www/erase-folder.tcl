# /packages/intranet-filestorage/www/intranet/filestorage/erase-file.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Show the content a specific subdirectory

    @param name
    @param project_id
    @param name
    @param return_url

    @author pvilarmau@hotmail.com
    @author santitrenchs@santitrenchs.com
    @author frank.bergmann@project-open.com
} {

    {folder ""}
    name
    project_id:notnull
    return_url:notnull
}

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set page_title "File Tree Competitiveness"
set context_bar [ad_context_bar_ws $page_title]
set page_focus ""
set group_id $project_id

set start_path $return_url

set current_user_id [ad_maybe_redirect_for_registration]
set return_url [im_url_with_query]

set query "select g.group_name as project_name from user_groups g where group_id=$group_id"


if { ![db_0or1row projects_info_query $query] } {
    ad_return_complaint 1 "Can't find the project with group id of $group_id"
    return
}


set page_content "
<table>
<tr>
  <td>
Are you sure to delete this folder?
</td></tr>
</table>
<table>
  <tr>
   <td>
    <form method='post' action='erase-folder-2.tcl?[export_url_vars group_id folder return_url start_path]'>
      <input type='submit' value='Erase'> 
    </form>
    </td>
   <td>
   <form method='post' action='$start_path'>
     <input type='submit' value='Cancel'>
   </form>
  </td>
 </tr>
</table>

"
db_release_unused_handles

set my_folder [im_filestorage_get_folder_name $folder]

set page_title "Delete folder '$my_folder'"
doc_return  200 text/html [im_return_template]









