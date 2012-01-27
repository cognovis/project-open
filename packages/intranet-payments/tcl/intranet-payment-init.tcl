# packages/intranet-payments/tcl/intranet-payment-init.tcl

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
    
    Callbacks for payments
    
    @author <yourname> (<your email>)
    @creation-date 2012-01-27
    @cvs-id $Id$
}

ad_proc -public -callback im_payment_after_create {
	{-payment_id:required}
	{-payment_method_id ""}
} {
    This callback allows you to execute action before and after every
    important change of object. Examples:
    - Copy preset values into the object
    - Integrate with external applications via Web services etc.
    
    @param payment_id ID of the payment
    @param payment_method_id ID of the Payment Method
} -

