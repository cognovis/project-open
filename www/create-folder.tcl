# /www/intranet/filestorage/erase-file.tcl

ad_page_contract {
    Show the content a specific subdirectory

    @param folder
    @param project_id
    @param folder_type
    @param return_url

    @author pvilarmau@hotmail.com
    @author santitrenchs@santitrenchs.com
    @cvs-id erase-file.tcl
} {

    {folder ""}
    {folder_type ""}
    project_id:notnull
    return_url:notnull
}

# User id already verified by filters
set user_id [ad_get_user_id]
set page_title "File Tree Competitiveness"
set context_bar [ad_context_bar_ws $page_title]

set start_path $return_url

set page_focus ""

set current_user_id [ad_maybe_redirect_for_registration]
set return_url [im_url_with_query]

set query "select g.group_name as project_name from user_groups g where group_id=$project_id"


if { ![db_0or1row projects_info_query $query] } {
    ad_return_complaint 1 "Can't find the project with group id of $project_id"
    return
}


set page_content "
<table>
<tr>
<td>
Enter the name of the folder
</td>
</tr>
<tr>
<td>
<form method='post' action='create-folder-2'>
<input type='text' name='folder_name' value='' style='width: 100%;'>
<input type='submit' value='create folder'>
<input type='hidden' name='folder' value='$folder'>
<input type='hidden' name='folder_type' value='$folder_type'>
<input type='hidden' name='project_id' value='$project_id'>
<input type='hidden' name='return_url' value='$return_url'>
<input type='hidden' name='start_path' value='$start_path'>
</form>
</td>
</tr>
</table>
<br>
"

db_release_unused_handles
set my_folder [im_filestorage_get_folder_name $folder]

set page_title "Upload into '$my_folder'"
doc_return  200 text/html [im_return_template]













