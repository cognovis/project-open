create table im_biz_object_members_availability (
       rel_id integer constraint rel_id_fk references im_biz_object_members(rel_id) on delete cascade,
       start_date date not null,
       availability float default 100,
       primary key(rel_id,start_date)
);
