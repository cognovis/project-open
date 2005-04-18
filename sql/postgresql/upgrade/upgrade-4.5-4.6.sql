-- @author Vinod Kurup vinod@kurup.com
-- @creation-date 2002-10-08

update acs_object_types
set table_name = 'acs_mail_queue_messages'
where lower(object_type) = 'acs_mail_queue_message';
