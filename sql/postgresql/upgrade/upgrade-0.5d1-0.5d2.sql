alter table acs_mail_log add constraint log_id_uq UNIQUE (log_id);

create table acs_mail_log_recipient_map (
	recipient_id		integer	constraint 
	 			acs_mail_log_recipient_id_fk
				references parties(party_id),
	log_id			integer	
 				constraint acs_mail_log_log_id_fk
				references acs_mail_log(log_id),
	type 			varchar(30)
);

create index acs_mail_log_recipient_map_log_idx on acs_mail_log_recipient_map(log_id);
create index acs_mail_log_recipient_map_recipient_idx on acs_mail_log_recipient_map(recipient_id);
create index acs_mail_log_um_log_rec_idx on acs_mail_log_recipient_map(log_id,recipient_id,type);

insert into acs_mail_log_recipient_map (recipient_id, log_id, type) select recipient_id, log_id, 'to' from acs_mail_log;
update acs_mail_log set cc = null;

alter table acs_mail_log add column bcc varchar(4000);
alter table acs_mail_log add column to_addr varchar(4000);
alter table acs_mail_log drop column recipient_id;

create or replace function acs_mail_log__new (integer,varchar, integer, integer, varchar, varchar,integer,varchar,integer,integer,varchar,varchar,varchar)
returns integer as '
declare	
	p_log_id alias for $1;
	p_message_id alias for $2;
	p_sender_id alias for $3;
	p_package_id alias for $4;
	p_subject alias for $5;
	p_body alias for $6;
	p_creation_user alias for $7;
        p_creation_ip alias for $8;
        p_context_id alias for $9;
	p_object_id alias for $10;
	p_cc alias for $11;
	p_bcc alias for $12;
	p_to_addr alias for $13;
	v_log_id acs_mail_log.log_id%TYPE;
begin
	v_log_id := acs_object__new (
		p_log_id,         -- object_id
		''mail_log'' -- object_type
	);

	insert into acs_mail_log
		(log_id, message_id, sender_id, package_id, subject, body, sent_date, object_id, cc, bcc, to_addr)
	values
		(v_log_id, p_message_id, p_sender_id, p_package_id, p_subject, p_body, now(), p_object_id, p_cc, p_bcc, p_to_addr);

	return v_log_id;

end;' language 'plpgsql';
