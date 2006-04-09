-- /packages/intranet-filestorage/sql/common/intranet-filestorage-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- Sets up the persisten memory about folders, their permissions
-- and the state (opened or closed) in which the user they have
-- left the last time he used the filestorage module.
--
-- @author Frank Bergmann (frank.bergmann@project-open.com)
--
-- Note: These tables are not yet used by the filestorage module,
-- but thought for the next version of the module.


---------------------------------------------------------
-- Categories
--

-- insert into im_categories
delete from im_categories where category_id >= 2420 and category_id < 2430;

INSERT INTO im_categories (category_id, category, category_description, category_type)
VALUES (
	2420,
	'upload',
	'im_task_actions.action_type_id for uploads',
	'Intranet File Action Type'
);

INSERT INTO im_categories (category_id, category, category_description, category_type)
VALUES (
	2421,
	'download',
	'',
	'Intranet File Action Type'
);
