--
-- Upgrade script
--
-- Adds useful views
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @cvs-id $Id: upgrade-1.1d1-1.2d1.sql,v 1.1 2006/10/25 17:55:34 cvs Exp $

alter table workflow_actions
	add description text;

alter table workflow_actions
	add description_mime_type varchar(200);

alter table workflow_actions 
  alter column description_mime_type set default 'text/plain';
