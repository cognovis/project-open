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
    
    Allow to reply to a logged e-mail
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-04-27
    @cvs-id $Id$
} {
    log_id:notnull
    {return_url ""}
} 

# Get the information of the message
db_1row get_message_info { }

set page_title "[_ intranet-mail.Reply_To]"

# Check if we have a sender_id to whom to reply to.
if {$sender_id eq ""} {
    set sender_addr $from_addr
} else {
    set sender_addr ""
}

# Set the cc_ids to all related object members
set cc_ids [list]
foreach member_id [im_biz_object_member_ids $object_id] {
    if {$member_id ne $sender_id} {
        lappend cc_ids $member_id
    }
}
