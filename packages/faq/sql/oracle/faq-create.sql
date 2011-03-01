-- Datamodel create for faq
--
-- @author @jennie.ybos.net,@wirth.ybos.net,openacs port @samir.symphinity.com
-- 
-- @cvs-id $Id: faq-create.sql,v 1.5 2004/04/01 22:52:45 jeffd Exp $
--
begin
     	acs_object_type.create_type (
			  supertype => 'acs_object',
			  object_type => 'faq',
			  pretty_name => 'FAQ',
			  pretty_plural => 'FAQs',
			  table_name => 'FAQS',
			  id_column => 'FAQ_ID'
	);
end;
/



create table faqs (
		faq_id    constraint faqs_faq_id_fk
			  references acs_objects (object_id)
			  constraint faqs_pk
			  primary key,
		faq_name  varchar (250)
		          constraint faqs_faq_name_nn
			  not null,
		separate_p char(1) default 'f' check(separate_p in ('f','t')), 
		disabled_p char(1) default 'f' check(disabled_p in ('f','t'))
);



begin
      	acs_object_type.create_type (
			  supertype => 'acs_object',
			  object_type => 'faq_q_and_a',
			  pretty_name => 'FAQ_Q_and_A',
			  pretty_plural => 'FAQ_Q_and_As',
			  table_name => 'FAQ_Q_AND_AS',
			  id_column => 'ENTRY_ID'
      	);
end;
/



create table faq_q_and_as (
	entry_id  constraint faq_q_and_as_entry_id_fk  
		  references acs_objects (object_id)
		  constraint faq_q_sand_a_pk
         	  primary key,
	faq_id	  integer references faqs not null,
	question  varchar (4000) not null,
	answer    varchar (4000) not null,
	-- determines the order of questions in a FAQ
	sort_key  integer not null
);



declare
      default_context acs_objects.object_id%TYPE;
      registered_users acs_objects.object_id%TYPE;
      the_public acs_objects.object_id%TYPE;

begin 
      acs_privilege.create_privilege('faq_view_faq');
      acs_privilege.create_privilege('faq_create_faq');
      acs_privilege.create_privilege('faq_delete_faq');
      acs_privilege.create_privilege('faq_modify_faq');
      acs_privilege.create_privilege('faq_view_q_and_a');
      acs_privilege.create_privilege('faq_create_q_and_a');
      acs_privilege.create_privilege('faq_delete_q_and_a');
      acs_privilege.create_privilege('faq_modify_q_and_a');
      acs_privilege.create_privilege('faq_admin_faq');
      acs_privilege.create_privilege('faq_admin_q_and_a');
      acs_privilege.add_child('faq_admin_faq', 'faq_view_faq');
      acs_privilege.add_child('faq_admin_faq', 'faq_create_faq');
      acs_privilege.add_child('faq_admin_faq', 'faq_delete_faq');
      acs_privilege.add_child('faq_admin_faq', 'faq_modify_faq');
      acs_privilege.add_child('faq_admin_q_and_a', 'faq_view_q_and_a');
      acs_privilege.add_child('faq_admin_q_and_a', 'faq_create_q_and_a');
      acs_privilege.add_child('faq_admin_q_and_a', 'faq_delete_q_and_a');
      acs_privilege.add_child('faq_admin_q_and_a', 'faq_modify_q_and_a'); 
      acs_privilege.add_child('faq_admin_faq', 'faq_admin_q_and_a');

      -- bind privileges to global names

      acs_privilege.add_child('create','faq_create_faq');
      acs_privilege.add_child('create','faq_create_q_and_a');
      acs_privilege.add_child('write','faq_modify_faq');
      acs_privilege.add_child('write','faq_modify_q_and_a');
      acs_privilege.add_child('read','faq_view_faq');
      acs_privilege.add_child('read','faq_view_q_and_a');
      acs_privilege.add_child('delete','faq_delete_faq');
      acs_privilege.add_child('delete','faq_delete_q_and_a');
      acs_privilege.add_child('admin','faq_admin_faq');  

      default_context := acs.magic_object_id('default_context');
      registered_users := acs.magic_object_id('registered_users');
      the_public := acs.magic_object_id('the_public'); 

      -- give the public the power to view faqs by default

      acs_permission.grant_permission (
         object_id => acs.magic_object_id('default_context'),
   	 grantee_id => acs.magic_object_id('the_public'),
         privilege => 'faq_view_faq'
       );


      -- give the public the power to view q_and_as by default

      acs_permission.grant_permission (
         object_id => acs.magic_object_id('default_context'),
	 grantee_id => acs.magic_object_id('the_public'),
         privilege => 'faq_view_q_and_a'
      );

end;
/

@@ faq-package-create.sql