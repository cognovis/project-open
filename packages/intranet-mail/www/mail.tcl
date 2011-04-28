# packages/intranet-mail/www/reply.tcl
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
    
    Allow to reply to write a new E-Mail
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-04-27
    @cvs-id $Id$
} {
    object_id:notnull
    {return_url ""}
} 

set page_title "[_ intranet-mail.New_Mail]"


# Set the cc_ids to all related object members
set party_ids [list]
foreach member_id [im_biz_object_member_ids $object_id] {
    if {[lsearch $party_ids $member_id]<0} {
        lappend party_ids $member_id
    }
}
