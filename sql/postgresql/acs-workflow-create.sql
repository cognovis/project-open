--
-- acs-workflow/sql/acs-workflow-create.sql
--
-- Calls the other SQL files to create the data models and PL/SQL packages.
--
-- @author Lars Pind (lars@pinds.com)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--

/* We create two sample processes */

\i wf-core-create.sql
\i workflow-case-package.sql
\i workflow-package.sql
\i wf-callback-package.sql
-- \i jobs-start.sql

-- \i sample-expenses-create.sql
\i sample-article-create.sql
