--
-- /packages/acs-kernel/sql/utilities-drop.sql
--
-- Purges useful PL/SQL utility routines.
--
-- @author Jon Salz (jsalz@mit.edu)
-- @creation-date 12 Aug 2000
-- @cvs-id $Id: utilities-drop.sql,v 1.2 2010/10/19 20:11:42 po34demo Exp $
--
\t
select drop_package('util');
\t
