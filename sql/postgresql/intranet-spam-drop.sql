delete from acs_mail_links where mail_link_id in (select spam_id from
spam_messages);

drop table spam_messages;
drop view spam_messages_all;

delete from acs_objects where object_type = 'spam_message';

select acs_object_type__drop_type(
        'spam_message',         -- object_type
        FALSE                    -- cascade_p
);


drop function spam__new (integer,varchar,timestamptz,text,varchar,text,varchar,varchar,integer,timestamptz,integer,varchar,varchar,boolean,varchar,timestamptz);

drop function spam__edit (integer,text,varchar,varchar,varchar,timestamptz);

drop function spam__new_content (integer,timestamptz,integer,varchar,varchar,varchar,varchar,integer);

drop function spam__approve (integer);
