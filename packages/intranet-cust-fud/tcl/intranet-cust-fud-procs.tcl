# 

## Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
# 

ad_library {
    
    FUD custom procs
    
    @author <yourname> (<your email>)
    @creation-date 2012-03-11
    @cvs-id $Id$
}

ad_proc -public fud_status_id {
    -project_status_id
} {
    if {"" eq $project_status_id} {set project_status_id 0}
    return $project_status_id
}