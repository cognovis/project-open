# /packages/intranet-customer-portal/www/upload-files-form.js.tcl 
#
# Copyright (C) 2011, ]project-open[
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

ad_page_contract {
    Builds ExtJS form for 'Inquire Quoute'

    @param dynview
    @author klaus.hofeditz@project-open.com
} {
    { security_token "" }
    inquiry_id:integer,optional
}

# ---------------------------------------------------------------
# Security 
# ---------------------------------------------------------------

# check if user is logged on 

# ---------------------------------------------------------------
# Settings
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# Build form 
# ---------------------------------------------------------------
# 
# show only for new customers

# set type to JS
if {[im_openacs54_p]} {
    ns_set put [ad_conn outputheaders] "content-type" "application/x-javascript; charset=utf-8"
}

# Get temp path for link 
set temp_path [parameter::get -package_id [apm_package_id_from_key intranet-customer-portal] -parameter "TempPath" -default "/tmp"]


