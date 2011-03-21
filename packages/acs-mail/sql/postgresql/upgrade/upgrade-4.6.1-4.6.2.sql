-- RI Indexes

create index acs_mail_links_body_id_idx ON acs_mail_links(body_id);
create index acs_mail_bodies_item_id_idx ON acs_mail_bodies(content_item_id);
create index acs_mail_bodies_body_from_idx ON acs_mail_bodies(body_from);
create index acs_mail_bodies_body_reply_idx ON acs_mail_bodies(body_reply_to);
create index acs_mail_mpp_cr_item_id_idx ON acs_mail_multipart_parts(content_item_id);

