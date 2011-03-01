--
-- upgrade attachments to include approved_p column
--
-- @author <a href="mailto:yon@openforce.net">yon@openforce.net</a>
-- @creation-date 2002-08-29
-- @version $Id: upgrade-0.1d-0.2.sql,v 1.1 2002/08/30 14:59:28 arjun Exp $
--

alter table attachments rename to attachments_old;

drop index attachments_pk;

create table attachments (
    object_id                   integer
				constraint attachments_object_id_fk
                                references acs_objects(object_id)
                                on delete cascade,
    item_id                     integer
				constraint attachments_item_id_fk
                                references acs_objects(object_id)
                                on delete cascade,
    approved_p                  char(1)
                                default 't'
                                constraint attachments_approved_p_ck
                                check (approved_p in ('t', 'f'))
                                constraint attachments_approved_p_nn
                                not null,
    constraint                  attachments_pk
                                primary key (object_id, item_id)
);

insert
into attachments
(object_id, item_id, approved_p)
select object_id,
       item_id,
       't'
from attachments_old;

drop table attachments_old;
