<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "http://www.thecodemill.biz/repository/xql.dtd">
<!-- packages/intranet-mail/tcl/intranet-mail-procs-postgresql.xql -->
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

  <rdbms>
    <type>postgresql</type>
    <version>8.4</version>
  </rdbms>
  
      <fullquery name="acs_mail_lite::complex_send.create_complex_queue_entry">
        <querytext>
            insert into acs_mail_lite_complex_queue
                  (id, 
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
         reply_to,
                   subject,
                   body,
                   package_id,
                   files,
                   file_ids,
                   folder_ids,
                   mime_type,
                   object_id,
                   single_email_p,
                   no_callback_p,
                   extraheaders,
                   alternative_part_p,
                   use_sender_p     
                  )
            values
                  (nextval('acs_mail_lite_id_seq'),
         :creation_date,
                   :locking_server,
                   :to_party_ids,
                   :cc_party_ids,
                   :bcc_party_ids,
                   :to_group_ids,
                   :cc_group_ids,
                   :bcc_group_ids,
                   :to_addr,
                   :cc_addr,
                   :bcc_addr,
                   :from_addr,
         :reply_to,
                   :subject,
                   :body,
                   :package_id,
                   :files,
                   :file_ids,
                   :folder_ids,
                   :mime_type,
                   :object_id,
                   (case when :single_email_p = '1' then TRUE else FALSE end),
                   (case when :no_callback_p = '1' then TRUE else FALSE end),
                   :extraheaders,
                   (case when :alternative_part_p = '1' then TRUE else FALSE end),
                   (case when :use_sender_p = '1' then TRUE else FALSE end)          
                  )
        </querytext>
    </fullquery>       

    <fullquery name="acs_mail_lite::complex_sweeper.get_complex_queued_messages">
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
         reply_to,
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
            where locking_server = '' or locking_server is NULL
        </querytext>
    </fullquery>    
</queryset>