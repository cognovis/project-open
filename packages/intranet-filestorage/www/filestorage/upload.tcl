# /intranet/filestorage/upload.tcl

ad_page_contract {
    Serve the user a form to upload a new file or URL

    @author aure@arsdigita.com
    @author frank.bergmann@project-open.com
    @creation-date 030909
} {
    folder:notnull
    {folder_type ""}
    project_id:notnull
    return_url:notnull
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "Upload New File/URL"

set context_bar [im_context_bar [list "/intranet/projects/" "Projects"]  [list "/intranet/projects/view?group_id=$project_id" "One Project"]  "Upload File"]

if {"" == $folder_type} {
    ad_return_complaint 1 "<LI>Internal Error: folder_type not specified"
    return
}

# replace the "root" folder "/" with an empty string
if {[string compare $folder "/"] == 0} {
    set folder ""
}

set alt_msg "Use the &quot;Browse...&quot; button to locate your file, then click &quot;Open&quot;."

set page_content "
<form enctype=multipart/form-data method=POST action=upload-2.tcl>
[export_form_vars folder folder_type project_id return_url]

                    <table border=0>
                      <tr> 
                        <td align=right>Filename: </td>
                        <td> 
                          <input type=file name=upload_file size=30>
                          <img src=/images/help.gif width=16 height=16 title=\"$alt_msg\" alt=\"$alt_msg\"> 
                        </td>
                      </tr>
<!--
                      <tr> 
                        <td align=right> Title: </td>
                        <td> 
                          <input size=40 name=file_title>
                        </td>
                      </tr>
                      <tr> 
                        <td valign=top align=right>Comments: </td>
                        <td colspan=2>
                          <textarea rows=5 cols=50 name=description wrap></textarea>
                        </td>
                      </tr>
-->
                      <tr> 
                        <td></td>
                        <td> 
                          <input type=submit value=\"Submit and Upload\">
                        </td>
                      </tr>
                    </table>
</form>
"

db_release_unused_handles


set page_title "Upload into '$folder'"
doc_return  200 text/html [im_return_template]
