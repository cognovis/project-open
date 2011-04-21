-- 
-- packages/intranet-mail/sql/postgresql/intranet-mail-create.sql
-- 
-- Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2011-04-21
-- @cvs-id $Id$
--

CREATE TABLE acs_mail_lite_complex_queue (
   id                          integer
                               constraint acs_mail_lite_complex_queue_pk
                               primary key,
   creation_date               text,
   locking_server              text,
   to_party_ids                text,
   cc_party_ids                text,
   bcc_party_ids               text,
   to_group_ids                text,
   cc_group_ids                text,
   bcc_group_ids               text,
   to_addr                     text,
   cc_addr                     text,
   bcc_addr                    text,
   from_addr                   text,
   reply_to                    text,
   subject                     text,
   body                        text,
   package_id                  integer,
   files                       text,
   file_ids                    text,
   folder_ids                  text,
   mime_type                   text,
   object_id                   integer,
   single_email_p              boolean,
   no_callback_p               boolean,
   extraheaders                text,
   alternative_part_p          boolean,
   use_sender_p                boolean
);
