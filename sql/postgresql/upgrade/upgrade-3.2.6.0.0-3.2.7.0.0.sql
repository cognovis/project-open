-- upgrade-3.2.6.0.0-3.2.7.0.0.sql


-------------------------------------------------------------
-- Allow to make quotes for both active and potential companies


insert into im_categories (
        CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID,
        CATEGORY, CATEGORY_TYPE
) values (
        '', 'f', '40',
        'Active or Potential', 'Intranet Company Status'
);

-- Introduce "Active or Potential" as supertype of both
-- "Acative" and "Potential"
--
-- im_category_hierarchy(parent, child)

INSERT INTO im_category_hierarchy 
	SELECT 40, child_id
	FROM im_category_hierarchy
	WHERE parent_id = 41
;

-- Make "Potential" and "Active" themselves children of "Act or Pot"
INSERT INTO im_category_hierarchy VALUES (40, 41);
INSERT INTO im_category_hierarchy VALUES (40, 46);

