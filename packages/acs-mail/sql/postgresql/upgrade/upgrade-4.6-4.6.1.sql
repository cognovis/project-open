-- @author Vinod Kurup vinod@kurup.com
-- @creation-date 2002-12-15

-- fix the primary key on the outgoing queue
create table acs_mail_o_tmp as select * from acs_mail_queue_outgoing;

drop table acs_mail_queue_outgoing;

create table acs_mail_queue_outgoing (
    message_id		integer
					constraint acs_mail_queue_out_mlid_fk
					references acs_mail_queue_messages on delete cascade,
    envelope_from	text,
    envelope_to		text,
	constraint acs_mail_queue_out_pk
	primary key (message_id, envelope_to)
);

insert into acs_mail_queue_outgoing select * from acs_mail_o_tmp;

drop table acs_mail_o_tmp;
