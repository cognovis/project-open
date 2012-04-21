# packages/intranet-collmex/tcl/intranet-collmex-procs.tcl

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
    
    Procedure to interact with collmex init file
    
    @author <yourname> (<your email>)
    @creation-date 2012-01-04
    @cvs-id $Id$
}

ad_schedule_proc -thread t 601 intranet_collmex::invoice_payment_get
