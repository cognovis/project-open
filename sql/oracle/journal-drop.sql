--
-- acs-kernel/sql/acs-objects-drop.sql
--
-- DDL commands to purge the ACS Objects data model
--
-- @author Lars Pind (lars@pinds.com)
-- @creation-date 2000-22-18
-- @cvs-id $Id: journal-drop.sql,v 1.2 2010/10/19 20:11:34 po34demo Exp $
--

begin
  acs_object_type.drop_type(
    object_type => 'journal_entry'
  );
end;
/
show errors

drop package journal_entry;
drop table journal_entries;
