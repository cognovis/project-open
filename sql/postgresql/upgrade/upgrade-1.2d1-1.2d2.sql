--
-- Upgrade script
--
-- Adds fields to workflows
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @cvs-id $Id$

alter table workflows
	add description text;

alter table workflows
	add description_mime_type varchar(200);

alter table workflows
  alter column description_mime_type set default 'text/plain';
