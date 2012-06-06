# /packages/intranet-timesheet2-invoices/upload-prices.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Serve the user a form to upload a new file or URL

    @author frank.bergmann@project-open.com
} {
    return_url:notnull
    company_id:integer
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-timesheet2-invoices.lt_Upload_Client_Prices_]"

set context_bar [im_context_bar [list "/intranet/companies/" "[_ intranet-timesheet2-invoices.Clients]"] "[_ intranet-timesheet2-invoices.Upload_CSV]"]

set page_body "
<form enctype=multipart/form-data method=POST action=upload-prices-2.tcl>
[export_form_vars company_id return_url]
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
                          <input type=submit value=\"[_ intranet-timesheet2-invoices.Submit_and_Upload]\">
                        </td>
                      </tr>
                    </table>
</form>
"

db_release_unused_handles

ad_return_template
