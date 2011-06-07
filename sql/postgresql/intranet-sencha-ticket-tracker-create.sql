
-- 
alter table im_tickets
add column ticket_fs_folder_id integer
constraint im_tickets_fs_folder_fk references cr_items;

