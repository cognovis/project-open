# /packages/intranet-core/www/intranet/companies/new.tcl
#                                                                                                   # Copyright (C) 2004 various parties
# The code is based on ArsDigita ACS 3.4
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
    Displays the editor for one absence.
    @param absence_id which component should be modified
    @param return_url the url to be send back after the saving

    @author mai-bee@gmx.net
} {
    {absence_id:integer 0}
}

set user_id [ad_maybe_redirect_for_registration]


set page_body [im_risk_project_component $user_id 3088]

doc_return  200 text/html [im_return_template]
