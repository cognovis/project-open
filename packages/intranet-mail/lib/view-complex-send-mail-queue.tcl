# packages/intranet-mail/lib/view-complex-send-mail-queue.tcl
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
## Complex Send queue
#
# @author Malte Sussdorff (malte.sussdorff@cognovis.de)
# @creation-date 2011-04-21
# @cvs-id $Id$

template::list::create \
   -name get_all_complex_queued_messages \
   -selected_format normal \
   -multirow messages \
    -elements {
        creation_date { label "[_ acs-mail-lite.Queueing_time]" }
        from_addr { label "[_ acs-mail-lite.Sender]" }
        to_addr { label "[_ acs-mail-lite.Recipients]" }
        subject { label "[_ acs-mail-lite.Subject]" }
        locking_server { label "[_ acs-mail-lite.Queue_server]" }
    }
        
db_multirow messages get_all_complex_queued_messages {}
