--
-- packages/acs-mail/sql/postgresql/acs-mail-nt-drop.sql
--
-- @author Vinod Kurup <vkurup@massmed.org>
-- @creation-date 2001-07-05
-- @cvs-id $Id$
--

-- FIXME: This script has NOT been tested! - vinodk

drop function acs_mail_nt__post_request(integer,integer,boolean,varchar,text,integer);
drop function acs_mail_nt__post_request(integer,integer,varchar,text);
drop function acs_mail_nt__cancel_request (integer);
drop function acs_mail_nt__expand_requests ();
drop function acs_mail_nt__update_requests ();
drop function acs_mail_nt__process_queue (varchar,integer);
drop function acs_mail_nt__schedule_process (numeric,varchar,integer);

