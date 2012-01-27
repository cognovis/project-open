-- upgrade-4.0.2.0.6-4.0.2.0.7.sql

SELECT acs_log__debug('/packages/intranet-sencha-ticket-tracker/sql/postgresql/upgrade/upgrade-4.0.2.0.6-4.0.2.0.7.sql','');


-- Custom Ticket Full-Text Search function

create or replace function im_tickets_tsearch ()
returns trigger as $body$
declare
	v_string	varchar;
begin
	select  coalesce(p.project_name, '') || ' ' ||
		coalesce(p.project_nr, '') || ' ' ||
		coalesce(p.project_path, '') || ' ' ||
		coalesce(p.description, '') || ' ' ||
		coalesce(p.note, '') || ' ' ||
		coalesce(t.ticket_note, '') || ' ' ||
		coalesce(t.ticket_description, '') || ' ' ||
		coalesce(t.ticket_file, '') || ' ' ||
		coalesce(im_category_from_id(t.ticket_origin), '') || ' ' ||
		coalesce(im_category_from_id(t.ticket_area_id), '') || ' ' ||
		coalesce(im_category_from_id(t.ticket_incoming_channel_id), '') || ' ' ||
		coalesce(im_category_from_id(t.ticket_outgoing_channel_id), '') || ' ' ||

		coalesce(im_name_from_user_id(cc_pers.person_id), '') || ' ' ||
		coalesce(cc_pers.telephone, '') || ' ' ||
		coalesce(cc_part.email, '') || ' ' ||

		coalesce(cust.company_name, '') || ' ' ||
		coalesce(cust.vat_number, '') || ' ' ||
		coalesce(cust.company_province, '') || ' ' ||

		coalesce(t.ticket_request, '') || ' ' ||
		coalesce(t.ticket_resolution, '') || ' ' ||
		coalesce(t.ticket_observations, '') || ' ' ||
		coalesce(t.ticket_answer, '')
	into    v_string
	from    im_tickets t
		LEFT OUTER JOIN persons cc_pers ON (t.ticket_customer_contact_id = cc_pers.person_id)
		LEFT OUTER JOIN parties cc_part ON (t.ticket_customer_contact_id = cc_part.party_id),
		im_projects p
		LEFT OUTER JOIN im_companies cust ON (p.company_id = cust.company_id),
		im_companies c
	where   
		t.ticket_id = p.project_id and
		p.company_id = c.company_id and
		p.project_id = new.ticket_id
	;

	perform im_search_update(new.ticket_id, 'im_ticket', new.ticket_id, v_string);

	return new;
end;$body$ language 'plpgsql';


update im_tickets set ticket_status_id = ticket_status_id;
