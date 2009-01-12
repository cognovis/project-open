-- upgrade-3.4.0.3.2-3.4.0.4.0.sql

-- Fix implementation for user skins

alter table users add skin_id integer references im_categories;

--        { 0  "left"          "Default" }
--        { 1  "opus5"         "Light Green" }
--        { 2  "default"       "Right Blue" }
--        { 4  "saltnpepper"   "SaltnPepper" }

SELECT im_category_new (40010, 'default', 'Intranet Skin');
SELECT im_category_new (40015, 'left', 'Intranet Skin');
SELECT im_category_new (40020, 'saltnpepper', 'Intranet Skin');
SELECT im_category_new (40025, 'lightgreen', 'Intranet Skin');

update im_categories set sort_order = 1 where category = 'left' and category_type = 'Intranet Skin';
update im_categories set sort_order = 2 where category = 'default' and category_type = 'Intranet Skin';
update im_categories set sort_order = 3 where category = 'saltnpepper' and category_type = 'Intranet Skin';
update im_categories set sort_order = 4 where category = 'lightgreen' and category_type = 'Intranet Skin';

-- update users set skin_id = 40010 where skin = 2;
update users set skin_id = 40015 where skin = 0;
update users set skin_id = 40020 where skin = 4;
update users set skin_id = 40025 where skin = 2;

update users set skin_id = 40015 where skin_id is null;

