create index acs_mail_log_object_idx on acs_mail_log(object_id);
create index acs_mail_log_recipient_idx on acs_mail_log(recipient_id);
create index acs_mail_log_sender_idx on acs_mail_log(sender_id);
alter table acs_mail_log add column cc varchar(4000);

create or replace function acs_mail_log__new (integer,varchar, integer, integer, integer, varchar, varchar,integer,varchar,integer,integer,varchar)
returns integer as '
declare	
	p_log_id alias for $1;
	p_message_id alias for $2;
	p_recipient_id alias for $3;
	p_sender_id alias for $4;
	p_package_id alias for $5;
	p_subject alias for $6;
	p_body alias for $7;
	p_creation_user alias for $8;
        p_creation_ip alias for $9;
        p_context_id alias for $10;
	p_object_id alias for $11;
	p_cc alias for $11;
	v_log_id acs_mail_log.log_id%TYPE;
begin
	v_log_id := acs_object__new (
		p_log_id,         -- object_id
		''mail_log'' -- object_type
	);

	insert into acs_mail_log
		(log_id, message_id, recipient_id, sender_id, package_id, subject, body, sent_date, object_id, cc)
	values
		(v_log_id, p_message_id, p_recipient_id, p_sender_id, p_package_id, p_subject, p_body, now(), p_object_id, p_cc);

	return v_log_id;

end;' language 'plpgsql';
