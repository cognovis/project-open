-- upgrade-3.4.0.4.0-3.4.0.5.0.sql

SELECT acs_log__debug('/packages/intranet-hr/sql/postgresql/upgrade/upgrade-3.4.0.4.0-3.4.0.5.0.sql','');


-- 41000-41099  Intranet Salutation (100)

SELECT im_category_new(41000, 'Dear Mr.', 'Intranet Salutation');
SELECT im_category_new(41001, 'Dear Mrs.', 'Intranet Salutation');
SELECT im_category_new(41002, 'Dear Ladies and Gentlemen', 'Intranet Salutation');
SELECT im_category_new(41003, 'Hey Dude', 'Intranet Salutation');



