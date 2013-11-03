--
-- upgrade attachments to include approved_p column
--
-- @author <a href="mailto:yon@openforce.net">yon@openforce.net</a>
-- @creation-date 2002-08-29
-- @version $Id$
--

alter table attachments add (
    approved_p                      char(1)
                                    default 't'
                                    constraint attachments_approved_p_ck
                                    check (approved_p in ('t', 'f'))
                                    constraint attachments_approved_p_nn
                                    not null
);
