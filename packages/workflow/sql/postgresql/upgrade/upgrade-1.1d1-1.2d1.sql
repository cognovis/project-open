--
-- Upgrade script
--
-- Adds useful views
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @cvs-id $Id$

alter table workflow_actions
	add description text;

alter table workflow_actions
	add description_mime_type varchar(200);

alter table workflow_actions 
  alter column description_mime_type set default 'text/plain';
