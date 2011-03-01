-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @author Frank Bergmann (frank.bergmann@project-open.com)
-- @creation-date 2004-09-06
-- @arch-tag: 0d6b6723-0e95-4c00-8a84-cb79b4ad3f9d
-- @cvs-id $Id: wiki-create.sql,v 1.2 2005/04/29 17:11:27 cvs Exp $
--

-- there seems to be an error in CMS 4.1.x with 
-- the view "cr_revisioni". This error seems to be due
-- to the fact that the content type "content_revision" hasn't
-- been created correctly. Strange stuff...
--
select content_type__refresh_view ('content_revision');

insert into cr_mime_types values ('Text - Wiki','text/x-openacs-wiki','');
insert into cr_mime_types values ('Text - Markdown','text/x-openacs-markdown','');