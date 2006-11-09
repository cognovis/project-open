-- -----------------------------------------------------
-- Update the date field of im_fs_actions 
-- from date to timestamp
--
-- This upgrade doesn't work directly in PG 7.4.x,
-- so we take the long way here.

-- Delete everything, because we don't get the unique
-- key otherwise.

delete from im_fs_actions;

alter table im_fs_actions 
	drop column action_date;

alter table im_fs_actions 
	add action_date timestamptz;

update im_fs_actions set action_date = now();

alter table im_fs_actions 
	alter column action_date set not null;

alter table im_fs_actions 
	add constraint im_fs_actions_pkey
	primary key (user_id, action_date, file_name);


alter table im_fs_files
add fti_content text;

