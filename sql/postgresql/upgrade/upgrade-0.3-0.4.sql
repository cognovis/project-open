-- RI indexes 
create index attachments_item_id_idx ON attachments(item_id);
create index attachments_fsr_fm_folder_id_i ON attachments_fs_root_folder_map(folder_id);

