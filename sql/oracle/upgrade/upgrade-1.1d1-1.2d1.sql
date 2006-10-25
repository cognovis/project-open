--
-- Upgrade script
--
-- Adds useful views
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @cvs-id $Id$

alter table workflow_actions add (
  description             clob,
  description_mime_type   varchar2(200) default 'text/plain'
);
