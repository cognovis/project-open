alter table 
    dav_site_node_folder_map 
drop constraint 
    dav_impls_folder_id_fk;

alter table 
    dav_site_node_folder_map 
add constraint 
    dav_impls_folder_id_fk 
        foreign key (folder_id) 
        references cr_folders 
            on delete cascade;
