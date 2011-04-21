<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "http://www.thecodemill.biz/repository/xql.dtd">
<!-- packages/intranet-mail/lib/view-complex-send-mail-queue.xql -->
<!-- 
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
-->
<!-- @author Malte Sussdorff (malte.sussdorff@cognovis.de) -->
<!-- @creation-date 2011-04-21 -->
<!-- @cvs-id $Id$ -->
<queryset>
     <fullquery name="get_all_complex_queued_messages">
       <querytext>
           select
                  id,
                  creation_date,
                  locking_server,
                  to_party_ids,
                  cc_party_ids,
                  bcc_party_ids,
                  to_group_ids,
                  cc_group_ids,
                  bcc_group_ids,
                  to_addr,
                  cc_addr,
                  bcc_addr,
                  from_addr,
                  subject,
                  body,
                  package_id,
                  files,
                  file_ids,
                  folder_ids,
                  mime_type,
                  object_id,
                  (case when single_email_p = TRUE then 1 else 0 end) as single_email_p,
                  (case when no_callback_p = TRUE then 1 else 0 end) as no_callback_p,
                  extraheaders,
                  (case when alternative_part_p = TRUE then 1 else 0 end) as alternative_part_p,
                  (case when use_sender_p = TRUE then 1 else 0 end) as use_sender_p
           from acs_mail_lite_complex_queue
           order by creation_date
       </querytext>
   </fullquery>             
</queryset>