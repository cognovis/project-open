--
-- Upgrade script
--
-- Adds fields to workflows
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @cvs-id $Id: upgrade-1.2d1-1.2d2.sql,v 1.1 2006/10/25 17:55:34 cvs Exp $

alter table workflows
	add description text;

alter table workflows
	add description_mime_type varchar(200);

alter table workflows
  alter column description_mime_type set default 'text/plain';
