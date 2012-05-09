-- 4.0.3.0.1-4.0.3.0.2.sql

SELECT acs_log__debug('/packages/intranet-freelance/sql/postgresql/upgrade/upgrade-4.0.3.0.1-4.0.3.0.2.sql','');


-----------------------------------------------------------
-- Category Ranges reservation
--
--  2020- 2039	Skill Types for consulting companies
-- 80000-89999  Additional skill types, see intranet-freelance-create for details (10000)
-- 80100-80199  Software Development Languages
-- 80200-80299  Operating Systems



delete from im_categories where category_id in (2020, 2022, 2024, 2026);
INSERT INTO im_categories VALUES (2020,'Software Development',null,'Intranet Skill Type','category','t','f',null, null, 'Intranet Skill Programming Language');
INSERT INTO im_categories VALUES (2022,'System Admin',null,'Intranet Skill Type','category','t','f',null, null, 'Intranet Skill SysAdmin Topic');
INSERT INTO im_categories VALUES (2024,'Business Sector',null,'Intranet Skill Type','category','t','f',null, null, 'Intranet Skill Business Sector');
INSERT INTO im_categories VALUES (2026,'Consulting Skills',null,'Intranet Skill Type','category','t','f',null, null, 'Intranet Skill Consulting Skill');

-----------------------------------------------------------
-- 80100-80199  Software Development Languages
--
SELECT im_category_new(80100, 'Abap', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80102, 'Ada', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80104, 'Assembly', 'Intranet Skill Programming Language');
SELECT im_category_new(80106, 'C#', 'Intranet Skill Programming Language');
SELECT im_category_new(80108, 'C', 'Intranet Skill Programming Language');
SELECT im_category_new(80110, 'C++', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80112, 'Cobol', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80114, 'ColdFusion', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80116, 'D', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80118, 'Delphi', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80120, 'Erlang', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80122, 'Forth', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80124, 'Fortran', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80126, 'Haskell', 'Intranet Skill Programming Language');
SELECT im_category_new(80128, 'Java', 'Intranet Skill Programming Language');
SELECT im_category_new(80130, 'JavaScript', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80132, 'Lisp', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80134, 'Lua', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80136, 'OCaml', 'Intranet Skill Programming Language');
SELECT im_category_new(80138, 'Objective C', 'Intranet Skill Programming Language');
SELECT im_category_new(80140, 'PHP', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80142, 'Pascal', 'Intranet Skill Programming Language');
SELECT im_category_new(80144, 'Perl', 'Intranet Skill Programming Language');
SELECT im_category_new(80146, 'Python', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80148, 'Rexx', 'Intranet Skill Programming Language');
SELECT im_category_new(80150, 'Ruby', 'Intranet Skill Programming Language');
SELECT im_category_new(80152, 'SQL', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80154, 'Scala', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80156, 'Scheme', 'Intranet Skill Programming Language');
SELECT im_category_new(80158, 'Shell', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80160, 'Smalltalk', 'Intranet Skill Programming Language');
SELECT im_category_new(80162, 'Tcl', 'Intranet Skill Programming Language');
SELECT im_category_new(80164, 'Visual Basic', 'Intranet Skill Programming Language');


-----------------------------------------------------------
-- 80200-80299  SysAdmin Topics

SELECT im_category_new(80200, 'OS Windows', 'Intranet Skill SysAdmin Topic');
SELECT im_category_new(80205, 'OS Linux', 'Intranet Skill SysAdmin Topic');
SELECT im_category_new(80210, 'OS OS-X', 'Intranet Skill SysAdmin Topic');
SELECT im_category_new(80215, 'OS AIX', 'Intranet Skill SysAdmin Topic');
SELECT im_category_new(80220, 'OS HP-UX', 'Intranet Skill SysAdmin Topic');

SELECT im_category_new(80250, 'DB PostgreSQL', 'Intranet Skill SysAdmin Topic');
SELECT im_category_new(80255, 'DB Oracle', 'Intranet Skill SysAdmin Topic');
SELECT im_category_new(80260, 'DB MS-SQL Server', 'Intranet Skill SysAdmin Topic');
SELECT im_category_new(80265, 'DB DB2', 'Intranet Skill SysAdmin Topic');



-----------------------------------------------------------
-- 80300-80399  Business Sectors

SELECT im_category_new(80300, 'Automotive', 'Intranet Skill Business Sector');
SELECT im_category_new(80305, 'Defense & Aerospace', 'Intranet Skill Business Sector');
SELECT im_category_new(80310, 'Energy & Utilities', 'Intranet Skill Business Sector');
SELECT im_category_new(80315, 'Financial', 'Intranet Skill Business Sector');
SELECT im_category_new(80320, 'ICT & Technology', 'Intranet Skill Business Sector');
SELECT im_category_new(80325, 'Manufacturing', 'Intranet Skill Business Sector');
SELECT im_category_new(80330, 'Pharma & Biotech', 'Intranet Skill Business Sector');
SELECT im_category_new(80335, 'Primary Sector', 'Intranet Skill Business Sector');
SELECT im_category_new(80340, 'Public Sector', 'Intranet Skill Business Sector');
SELECT im_category_new(80345, 'Services', 'Intranet Skill Business Sector');




-----------------------------------------------------------
-- 80400-80499  Consulting Skill

SELECT im_category_new(80400, 'Junior Consultant', 'Intranet Skill Consulting Skill');
SELECT im_category_new(80410, 'Consultant', 'Intranet Skill Consulting Skill');
SELECT im_category_new(80420, 'Senior Consultant', 'Intranet Skill Consulting Skill');
SELECT im_category_new(80430, 'Project Management', 'Intranet Skill Consulting Skill');
SELECT im_category_new(80440, 'Change Management', 'Intranet Skill Consulting Skill');
SELECT im_category_new(80450, 'Process Analysis', 'Intranet Skill Consulting Skill');
SELECT im_category_new(80460, 'User Training', 'Intranet Skill Consulting Skill');
SELECT im_category_new(80470, 'Admin Training', 'Intranet Skill Consulting Skill');

