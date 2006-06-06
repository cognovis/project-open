-- upgrade-3.2.0.0.0-3.2.1.0.0.sql


-----------------------------------------------------------
-- Copy 'Intranet Project Type' Category into the range
-- of 4000-4099
-----------------------------------------------------------

-- 2006-05-28: Not possible: The static WF uses the hard
-- coded Intranet Project Type values...

-- Set the counter for the next categories to above the fixed
-- category range.


-----------------------------------------------------------
-- Add a "tm_type_id" field to im_trans_tasks and 
-- define categories

-- 4100-4199    Intranet Trans TM Type

INSERT INTO im_categories (category_id, category, category_type, category_description) VALUES
(4100,'Trados', 'Intranet Translation TM Type','Trados is integrated by up/downloading files');
INSERT INTO im_categories (category_id, category, category_type, category_description) VALUES
(4102,'Ophelia', 'Intranet Translation TM Type','Ophelia in integrated via UserExists');

alter table im_trans_tasks
add tm_type_id integer references im_categories;

alter table im_trans_tasks alter column tm_type_id 
set default 4100;

update im_trans_tasks set tm_type_id = 4100;








