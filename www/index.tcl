# /packages/intranet-invoices/www/index.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Offers a menu to create new Invoices, Quotes, POs
    and Bills

    @author frank.bergmann@project-open.com
} {
    { project_id 0 }
    { customer_id 0 }
}
set user_id [ad_maybe_redirect_for_registration]
ad_returnredirect "list"
return
