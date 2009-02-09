-- contacts-drop.sql
--
-- @author Matthew Geddert openacs@geddert.com
-- @creation-date 2004-07-28
-- @cvs-id $Id$
--
--

-- Drop Service Contracts
delete from acs_sc_impl_aliases
where impl_name = 'contacts_group_notif_type';


select	notification_type__delete(type_id)
from	notification_types 
where	short_name = 'contacts_group_notif';

select acs_sc_impl__delete(impl_name, impl_contract_name) 
from acs_sc_impls 
where impl_name in (
		'contacts_group_notif_type'
);


drop view contact_owners;
drop table contact_owner_rels;
drop table contact_list_members;
drop table contact_lists;

drop view contact_messages;
drop table contact_privacy;
drop table contact_message_log;
drop table contact_message_items;
drop table contact_message_types;
select acs_rel_type__drop_type('contact_message_log','t');



-- Searches

select acs_object__delete(search_id) from contact_searches;
select acs_object_type__drop_type('contact_search','t');
select acs_object_type__drop_type ('contact_list','t');

drop table contact_search_log;
drop table contact_search_extend_map;
drop table contact_search_conditions;
drop table contact_searches;
drop table contact_extend_options;


drop view contact_rel_types;
drop table contact_signatures;
drop table contact_groups;
drop table contact_rels;
drop table organization_rels;
drop table contact_complaint_track;


select content_type__drop_type ('contact_party_revision','t','t');
--drop table contact_party_revisions;
select acs_rel_type__drop_type('contact_owner','t');
select acs_rel_type__drop_type('organization_rel','t');
select acs_rel_type__drop_type('main_office_rel','t');
select acs_rel_type__drop_type(object_type,'t') from acs_object_types where supertype = 'contact_rel';
select acs_rel_type__drop_type('contact_rel','t');

-- procedure drop_type
select drop_package('contact');
select drop_package('contact_rel');
select drop_package('contact_party_revision');
select drop_package('contact_list');
select drop_package('contact_owner');

drop sequence contact_extend_search_seq;

drop table contact_groups_allowed_rels;
drop table contact_deleted_history;


select drop_package('contact_search');


