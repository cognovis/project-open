--
-- Upgrade script
--
-- Adds new fields to workflows
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @cvs-id $Id$

alter table workflows add (
  description             clob,
  description_mime_type   varchar2(200) default 'text/plain'
);
