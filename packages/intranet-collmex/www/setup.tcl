# packages/intranet-collmex/www/setup.tcl
#
# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
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
 
ad_page_contract {
    
    setup for kolibiri
    
    @author <yourname> (<your email>)
    @creation-date 2012-01-05
    @cvs-id $Id$
} {
    
} -properties {
} -validate {
} -errors {
}

db_dml update_country_code "update im_offices set address_country_code = 'de' where address_country_code is null"

#db_foreach company_without_primary_contact {select company_id from im_companies where primary_contact_id is null} {
   
set providers [db_list providers "select company_id from im_companies where company_type_id in (10000305,58,59,56) and collmex_id is null"]

foreach company_id $providers {
    ds_comment [intranet_collmex::update_company -company_id $company_id]
}

set customers [db_list customers "select company_id from im_companies where company_type_id in (57,54,55, 10000006, 10000008, 10000009,10244,10245) and collmex_id is null"]

foreach company_id $customers {
    ds_comment [intranet_collmex::update_company -company_id $company_id -customer]
}