-- packages/acs-events/sql/postgresql/test/utest-drop.sql
--
-- Drop the unit test package
--
-- @author jowell@jsabino.com
-- @creation-date 2001-06-26
--
-- $Id: utest-drop.sql,v 1.1 2001/07/13 03:16:32 jowells Exp $

-- For now, we require openacs4 installed.
select drop_package('ut_assert');




