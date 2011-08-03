# /packages/intranet-sencha-ticket-tracker/www/index.tcl
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


# ---------------------------------------------------------------
#
# ---------------------------------------------------------------

ad_page_contract { 
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2011-05
    @cvs-id $Id$
} {

}

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

# Make sure the user is logged in.
# Otherwise Sencha will get an error in the REST backend.
set user_id [auth::require_login]
set user_is_employee_p [im_user_is_employee_p $user_id]

if {!$user_is_employee_p} {
    # ad_return_complaint 1 "The current user #$user_id is not member of the group Employees"
}