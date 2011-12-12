0;95;c-- 
-- packages/intranet-cust-kolibri/sql/postgresql/kolibri.sql
-- 
-- Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- @author <yourname> (<your email>)
-- @creation-date 2011-11-25
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-cust-kolibri/sql/postgresql/kolibri.sql','');

-- Update the customer data
-- get the contact

update im_offices set address_line1= wa_line1, address_line2 = wa_line2, address_city = wa_city, address_state=wa_state, address_postal_code=wa_postal_code, address_country_code = wa_country_code from users_contact, acs_rels where rel_type = 'im_company_employee_rel' and object_id_one = company_id and address_line1 is null and user_id = object_id_two;

update im_offices set address_line1= ha_line1, address_line2 = ha_line2, address_city = ha_city, address_state=ha_state, address_postal_code=ha_postal_code, address_country_code = ha_country_code from users_contact, acs_rels where rel_type = 'im_company_employee_rel' and object_id_one = company_id and address_line1 is null and user_id = object_id_two;

-- Move kontakt notes
update users_contact set note=null where note='';

create or replace function inline_0 ()
returns integer as $body$
declare
        v_note_id                 integer;
	v_note                  record;
begin
	for v_note in
        select note,user_id
        from users_contact
	where note is not null and note != ''
        loop
		v_note_id := im_note__new(
			null,
			'im_note',
			now(),
			v_note.user_id,
			'[ad_conn peeraddr]',
			null,
			v_note.note,
			v_note.user_id,
			11514,
			11400);
		update users_contact set note = '' where user_id = v_note.user_id;
end loop; 
        return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

create or replace function inline_0 ()
returns integer as $body$
declare
        v_note_id                 integer;
	v_note                  record;
begin
	for v_note in
        select note,user_id
        from im_freelancers
	where note is not null and note != ''
        loop
		v_note_id := im_note__new(
			null,
			'im_note',
			now(),
			v_note.user_id,
			'[ad_conn peeraddr]',
			null,
			v_note.note,
			v_note.user_id,
			11514,
			11400);
		update users_contact set note = '' where user_id = v_note.user_id;
end loop; 
        return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

-- Disable Expected Quality
update im_categories set enabled_p = 'f' where category_id = 2016;

-- Move Note component up
update im_component_plugins set sort_order = 10 where plugin_id = 29115;
update im_component_plugins set enabled_p = 'f' where plugin_id = 30328;



-- DYNFIELDS
select im_dynfield_attribute_new (
	  	 'im_company',			-- object_type
		 'bank_account_nr',			-- column_name
		 '#intranet-cust-kolibri.Bank_Account_Nr#',	-- pretty_name
		 'textbox_medium',			-- widget_name
		 'string',				-- acs_datatype
		 'f',					-- required_p   
		 50,					-- pos y
		 'f',					-- also_hard_coded
		 'im_companies'			-- table_name
	  );

select im_dynfield_attribute_new (
	  	 'im_company',			-- object_type
		 'bank_routing_nr',			-- column_name
		 '#intranet-cust-kolibri.Bank_Routing_Nr#',	-- pretty_name
		 'textbox_medium',			-- widget_name
		 'string',				-- acs_datatype
		 'f',					-- required_p   
		 51,					-- pos y
		 'f',					-- also_hard_coded
		 'im_companies'			-- table_name
	  );

select im_dynfield_attribute_new (
	  	 'im_company',			-- object_type
		 'bank_name',			-- column_name
		 '#intranet-cust-kolibri.Bank_Name#',	-- pretty_name
		 'textbox_medium',			-- widget_name
		 'string',				-- acs_datatype
		 'f',					-- required_p   
		 52,					-- pos y
		 'f',					-- also_hard_coded
		 'im_companies'			-- table_name
	  );

select im_dynfield_attribute_new (
	  	 'im_company',			-- object_type
		 'iban',			-- column_name
		 '#intranet-cust-kolibri.iban#',	-- pretty_name
		 'textbox_medium',			-- widget_name
		 'string',				-- acs_datatype
		 'f',					-- required_p   
		 53,					-- pos y
		 'f',					-- also_hard_coded
		 'im_companies'			-- table_name
	  ) from dual;

select im_dynfield_attribute_new (
	  	 'im_company',			-- object_type
		 'bic',			-- column_name
		 '#intranet-cust-kolibri.bic#',	-- pretty_name
		 'textbox_medium',			-- widget_name
		 'string',				-- acs_datatype
		 'f',					-- required_p   
		 54,					-- pos y
		 'f',					-- also_hard_coded
		 'im_companies'			-- table_name
	  );

select im_dynfield_attribute_new (
	  	 'im_company',			-- object_type
		 'paypal_email',			-- column_name
		 '#intranet-cust-kolibri.paypal_email#',	-- pretty_name
		 'textbox_medium',			-- widget_name
		 'string',				-- acs_datatype
		 'f',					-- required_p   
		 55,					-- pos y
		 'f',					-- also_hard_coded
		 'im_companies'			-- table_name
	  );

select im_dynfield_attribute_new (
	  	 'im_company',			-- object_type
		 'skrill_email',			-- column_name
		 '#intranet-cust-kolibri.skrill_email#',	-- pretty_name
		 'textbox_medium',			-- widget_name
		 'string',				-- acs_datatype
		 'f',					-- required_p   
		 56,					-- pos y
		 'f',					-- also_hard_coded
		 'im_companies'			-- table_name
	  );

update im_companies set bank_account_nr = bank_account, bank_routing_nr = bank from im_freelancers, acs_rels where rel_type = 'im_company_employee_rel' and object_id_one = company_id and user_id = object_id_two;
