-- upgrade-4.5.3-4.5.4.sql

-- Localization

SELECT im_lang_add_message('en_US','acs-workflow','Task_Has_Not_Been_Started_Yet','This task has not been started yet.');
SELECT im_lang_add_message('de_DE','acs-workflow','Task_Has_Not_Been_Started_Yet','Workflow Aufgabe noch nicht gestarted');

SELECT im_lang_add_message('en_US','acs-workflow','You_Are_The_Only_Person','You are the only person assigned to this task.');
SELECT im_lang_add_message('de_DE','acs-workflow','You_Are_The_Only_Person','Sie sind alleiniger Aufgabentr&auml;ger ');

SELECT im_lang_add_message('en_US','acs-workflow','Other_Assignees','Other assignees:');
SELECT im_lang_add_message('de_DE','acs-workflow','Other_Assignees','Weitere Aufgabentr@auml;ger:');

SELECT im_lang_add_message('en_US','acs-workflow','Assign_Yourself','assign yourself');
SELECT im_lang_add_message('de_DE','acs-workflow','Assign_Yourself','Aufgabe selbst ausf&uuml;hren');

SELECT im_lang_add_message('en_US','acs-workflow','Reassign','reassign');
SELECT im_lang_add_message('de_DE','acs-workflow','Reassign','Aufgabe anderer Person zuordnen');


