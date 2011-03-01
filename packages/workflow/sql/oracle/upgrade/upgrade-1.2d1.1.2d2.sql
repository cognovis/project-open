--
-- Upgrade script
--
-- Adds new fields to workflows
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @cvs-id $Id: upgrade-1.2d1.1.2d2.sql,v 1.1 2006/10/25 17:55:34 cvs Exp $

alter table workflows add (
  description             clob,
  description_mime_type   varchar2(200) default 'text/plain'
);
