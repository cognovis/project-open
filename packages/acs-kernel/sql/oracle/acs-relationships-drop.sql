--
-- packages/acs-kernel/sql/acs-relationships-drop.sql
--
-- @creation-date 2000-08-13
--
-- @author rhs@mit.edu
--
-- @cvs-id $Id: acs-relationships-drop.sql,v 1.2 2010/10/19 20:11:33 po34demo Exp $
--

drop package acs_rel;
drop package acs_rel_type;
drop table acs_rels;
drop sequence acs_rel_id_seq;
drop table acs_rel_types;
drop table acs_rel_roles;
