--  upgrade-3.4.0.8.5-3.4.0.8.6.sql

SELECT acs_log__debug('/packages/intranet-reporting-translation/sql/postgresql/upgrade/upgrade-3.4.0.8.5-3.4.0.8.6.sql','');

update im_menus 
set url = '/intranet-reporting-translation/trans-pm-productivity?' 
where url = '/intranet-reporting-translation/trans-pm-productivity';

update im_menus 
set url = '/intranet-reporting-translation/project-trans-tasks?' 
where url = '/intranet-reporting-translation/project-trans-tasks';

