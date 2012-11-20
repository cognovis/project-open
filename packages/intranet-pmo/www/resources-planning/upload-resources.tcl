ad_page_contract {
    @author malte.sussdorff@cognovis.de
} {
}

set return_url "/intranet"
set user_id [ad_maybe_redirect_for_registration]
set page_title "Upload Resources CSV"
set context_bar [im_context_bar [list "/intranet/users/" "Users"] $page_title]

set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_body "
<form enctype=multipart/form-data method=POST action=upload-resources-2.tcl>
[export_form_vars return_url]
                    <table border=0>
                      <tr> 
                        <td align=right>Filename: </td>
                        <td> 
                          <input type=file name=upload_file size=30>
                          [im_gif help "Use the &quot;Browse...&quot; button to locate your file, then click &quot;Open&quot;."]
                        </td>
                      </tr>
                      <tr> 
                        <td></td>
                        <td> 
                          <input type=submit value=Submit and Upload>
                        </td>
                      </tr>
                    </table>
</form>
"

