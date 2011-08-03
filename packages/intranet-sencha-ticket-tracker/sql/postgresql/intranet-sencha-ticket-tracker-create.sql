

alter table im_biz_objects
add column fs_folder_id integer
constraint im_tickets_fs_folder_fk references cr_items;

alter table im_biz_objects
add column fs_folder_path text;


alter table im_tickets
add column ticket_file text;
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_file', 'Ticket File', 'textbox_medium', 'string', 'f');



alter table im_tickets
add column ticket_request text;
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_request', 'Ticket Request', 'textbox_medium', 'string', 'f');



alter table im_tickets
add column ticket_resolution text;
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_resolution', 'Ticket Resolution', 'textbox_medium', 'string', 'f');



alter table im_companies
add column company_province text;
SELECT im_dynfield_attribute_new ('im_company', 'company_province', 'Province', 'textbox_medium', 'string', 'f');



alter table im_tickets
add column ticket_escalation_date timestamptz;
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_escalation_date', 'Escalation Date', 'date', 'string', 'f');


SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_creation_date', 'Creation Date', 'date', 'string', 'f');


SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_reaction_date', 'Reaction Date', 'timestamp', 'string', 'f');


SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_confirmation_date', 'Confirmation Date', 'timestamp', 'string', 'f');


alter table im_tickets
add column ticket_resolution_date timestamptz;
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_resolution_date', 'Resolution Date', 'timestamp', 'string', 'f');


SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_done_date', 'Done Date', 'timestamp', 'string', 'f');


SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_signoff_date', 'Sign Off Date', 'timestamp', 'string', 'f');

alter table im_tickets
add column ticket_requires_addition_info_p char(1);
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_requires_addition_info_p', 'Requires Additional ', 'checkbox', 'string', 'f');


alter table im_tickets
add column ticket_service_type_id integer
constraint ticket_service_type_fk references im_categories;
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_service_type_id', 'Service Type', 'ticket_status', 'integer', 'f');


alter table im_tickets
add column ticket_area_id integer
constraint ticket_area_fk references im_categories;
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_area_id', 'Area', 'ticket_status', 'integer', 'f');


alter table im_tickets
add column ticket_incoming_channel_id integer
constraint ticket_incoming_channel references im_categories;
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_incoming_channel_id', 'Incoming Channel', 'ticket_status', 'integer', 'f');



alter table im_tickets
add column ticket_outgoing_channel_id integer
constraint ticket_outgoing_channel references im_categories;
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_outgoing_channel_id', 'Outgoing Channel', 'ticket_status', 'integer', 'f');




SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'profile', 'Profile', 'Profiles',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
		select g.group_id, g.group_name
		from groups g, im_profiles p
		where g.group_id = p.profile_id
	}}}'
);


SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_queue_id', 'Ticket Queue', 'profile', 'integer', 'f');


alter table im_tickets
add column ticket_last_queue_id integer
constraint ticket_last_queue_id references parties;
SELECT im_dynfield_attribute_new ('im_ticket', 'ticket_last_queue_id', 'Ticket Last Queue', 'profile', 'integer', 'f');




-- alter table im_tickets alter column ticket_closed_in_1st_contact_p type text;
alter table im_tickets
add column ticket_closed_in_1st_contact_p text;

alter table im_tickets alter column ticket_requires_addition_info_p type text;

alter table im_tickets alter column ticket_creation_date type timestamptz;
alter table im_tickets alter column ticket_reaction_date type timestamptz;
alter table im_tickets alter column ticket_confirmation_date type timestamptz;
alter table im_tickets alter column ticket_done_date type timestamptz;
alter table im_tickets alter column ticket_signoff_date type timestamptz;
alter table im_tickets alter column ticket_escalation_date type timestamptz;
alter table im_tickets alter column ticket_resolution_date type timestamptz;






create or replace function im_category_indent (integer)
returns varchar as $body$
DECLARE
	v_len		integer;
	v_result	varchar;
BEGIN
	v_len = (length(im_category_path_to_category($1,0)) - 8);
	v_result := '';
	WHILE v_len > 0 LOOP
		v_result := v_result || '&nbsp;';
		v_len := v_len - 1;
	END LOOP;

	RETURN v_result;
END;
$body$ language 'plpgsql';











-----------------------------------------------------------------------
-- Categories
-- 76000-76999  Intranet Sencha Ticket Tracker (1000)


-- 76000
SELECT im_category_new(76000, 'Promocion Empresarial', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76002, 'Connect', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76004, 'Miniconnect', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76006, 'Crear empresas - Centros Tecnologicos', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76008, 'Crear empresas - Universidades', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76010, 'Business Angels', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76012, 'Gauzatu Industria', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76014, 'Gauzatu Implantaciones exteriores', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76016, 'Gauzatu Turismo', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76018, 'AFI Industria', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76020, 'AFI Comercio', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76022, 'AFI Turismo', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76024, 'Maquina Herramienta', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76026, 'MEP', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76028, 'Sucesiones', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76030, 'Transmision Empresarial y Emprendizaje', 'Intranet Sencha Ticket Tracker Area');

update im_categories set aux_string1 = 'BE-XXXX-2011' where category_id = 76002;
update im_categories set aux_string1 = 'BE-XXXX-2011' where category_id = 76004;
update im_categories set aux_string1 = 'CET-XX-2011' where category_id = 76006;
update im_categories set aux_string1 = 'CEU-XX-2011' where category_id = 76008;
update im_categories set aux_string1 = 'BA-XX-2011' where category_id = 76010;
update im_categories set aux_string1 = 'GZI-XXXX-2011' where category_id = 76012;
update im_categories set aux_string1 = 'GZIMP-XXXX-2011' where category_id = 76012;
update im_categories set aux_string1 = 'GZT-XXXX-2011' where category_id = 76016;
update im_categories set aux_string1 = 'XXXX-11' where category_id = 76018;
update im_categories set aux_string1 = 'XXXX-11' where category_id = 76020;
update im_categories set aux_string1 = 'XXXX-11' where category_id = 76022;
update im_categories set aux_string1 = 'MH-XXXX-11' where category_id = 76024;
update im_categories set aux_string1 = 'MEP-XXXX-2011' where category_id = 76026;
update im_categories set aux_string1 = 'XXX-11' where category_id = 76028;
update im_categories set aux_string1 = 'XXXXXXXXXXXXXXXXXX' where category_id = 76030;

SELECT im_category_hierarchy_new(76002, 76000);
SELECT im_category_hierarchy_new(76004, 76000);
SELECT im_category_hierarchy_new(76006, 76000);
SELECT im_category_hierarchy_new(76008, 76000);
SELECT im_category_hierarchy_new(76010, 76000);
SELECT im_category_hierarchy_new(76012, 76000);
SELECT im_category_hierarchy_new(76014, 76000);
SELECT im_category_hierarchy_new(76016, 76000);
SELECT im_category_hierarchy_new(76018, 76000);
SELECT im_category_hierarchy_new(76020, 76000);
SELECT im_category_hierarchy_new(76022, 76000);
SELECT im_category_hierarchy_new(76024, 76000);
SELECT im_category_hierarchy_new(76026, 76000);
SELECT im_category_hierarchy_new(76028, 76000);
SELECT im_category_hierarchy_new(76030, 76000);


SELECT im_category_new(76200, 'Sociedad de la Informacion', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76202, 'Mejora + Digital@', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76204, 'Asociacion + Digital@', 'Intranet Sencha Ticket Tracker Area');
update im_categories set aux_string1 = 'XXXXX-11' where category_id = 76202;
update im_categories set aux_string1 = 'XXXX-11' where category_id = 76204;
SELECT im_category_hierarchy_new(76202, 76200);
SELECT im_category_hierarchy_new(76204, 76200);

SELECT im_category_new(76400, 'Transformacion Empresarial', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76402, 'Compite Agentes', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76404, 'Compite Agentes Comercio', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76406, 'Compite Empresas', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76408, 'Itinerarios', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76410, 'Aldatu', 'Intranet Sencha Ticket Tracker Area');
update im_categories set aux_string1 = 'AD-2011-XXXX' where category_id = 76402;
update im_categories set aux_string1 = 'AT-2011-XXXX' where category_id = 76404;
update im_categories set aux_string1 = 'AB-2011-XXXX' where category_id = 76406;
update im_categories set aux_string1 = 'YYY-XXXX-10' where category_id = 76408;
update im_categories set aux_string1 = 'AL-2011-XXXX' where category_id = 76410;
SELECT im_category_hierarchy_new(76402, 76400);
SELECT im_category_hierarchy_new(76404, 76400);
SELECT im_category_hierarchy_new(76406, 76400);
SELECT im_category_hierarchy_new(76408, 76400);
SELECT im_category_hierarchy_new(76410, 76400);

SELECT im_category_new(76600, 'Tecnologia y Innovacion', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76602, 'Gaitek', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76604, 'Hedatu', 'Intranet Sencha Ticket Tracker Area');
SELECT im_category_new(76606, 'Nets', 'Intranet Sencha Ticket Tracker Area');
update im_categories set aux_string1 = 'IG-2011-XXXX' where category_id = 76602;
update im_categories set aux_string1 = 'IG-2011-XXXX' where category_id = 76604;
update im_categories set aux_string1 = 'IG-2011-XXXX' where category_id = 76606;
SELECT im_category_hierarchy_new(76602, 76600);
SELECT im_category_hierarchy_new(76604, 76600);
SELECT im_category_hierarchy_new(76606, 76600);



alter table persons
add column last_name2 text;
SELECT im_dynfield_attribute_new ('person', 'last_name2', 'Last Name 2', 'textbox_medium', 'string', 'f');

alter table persons
add column telephone text;
SELECT im_dynfield_attribute_new ('person', 'telephone', 'Telephone', 'textbox_medium', 'string', 'f');

alter table persons
add column gender text;
SELECT im_dynfield_attribute_new ('person', 'gender', 'Gender', 'textbox_medium', 'string', 'f');

alter table persons
add column language text;
SELECT im_dynfield_attribute_new ('person', 'language', 'Language', 'textbox_medium', 'string', 'f');

alter table persons
add column asterisk_user_id text;
SELECT im_dynfield_attribute_new ('person', 'asterisk_user_id', 'Asterisk User ID', 'textbox_medium', 'string', 'f');
update persons set asterisk_user_id = person_id;

