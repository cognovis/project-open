
-- 
alter table im_tickets
add column ticket_fs_folder_id integer
constraint im_tickets_fs_folder_fk references cr_items;



alter table im_tickets
add column ticket_file text;
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_file', 'Ticket File', 'textbox_medium', 'string', 'f');



alter table im_companies
add column company_province text;
SELECT im_dynfield_attribute_new ('im_company', 'company_province', 'Province', 'textbox_medium', 'string', 'f');



