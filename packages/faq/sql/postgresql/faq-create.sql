-- @jennie.ybos.net
-- @wirth.ybos.net
--openacs port @samir.symphinity.com


create function inline_0 ()
returns integer as '
begin
    PERFORM acs_object_type__create_type (
	''faq'',			-- object_type
	''FAQ'',			-- pretty_name
	''FAQs'',			-- pretty_plural
	''acs_object'',		-- supertype
	''FAQS'',			-- table_name
	''FAQ_ID'',		-- id_column
	null,				-- package_name
	''f'',				-- abstract_p
	null,				-- type_extension_table
	''faq.name''		-- name_method
	);

  return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


create table faqs (
		faq_id    integer constraint faqs_faq_id_fk
			  references acs_objects(object_id)
			  constraint faqs_pk
			  primary key,
		faq_name  varchar (250)
		          constraint faqs_faq_name_nn   not null,
		separate_p boolean  check(separate_p in ('f','t')),
		disabled_p char(1) default 'f' check(disabled_p in ('f','t'))
);


create function inline_1 ()
returns integer as '
begin
    PERFORM acs_object_type__create_type (
	''faq_q_and_a'',			-- object_type
	''FAQ_Q_and_A'',			-- pretty_name
	''FAQ_Q_and_As'',			-- pretty_plural
	''acs_object'',		-- supertype
	''FAQ_Q_AND_AS'',			-- table_name
	''ENTRY_ID'',		-- id_column
	null,				-- package_name
	''f'',				-- abstract_p
	null,				-- type_extension_table
	null		-- name_method
	);

  return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1 ();


create table faq_q_and_as (
	entry_id  integer constraint faq_q_and_as_entry_id_fk
		  references acs_objects (object_id)
		  constraint faq_q_sand_a_pk
         	  primary key,
	faq_id	  integer references faqs not null,
	question  varchar (4000) not null,
	answer    varchar (4000) not null,
	-- determines the order of questions in a FAQ
	sort_key  integer not null
);

create 	function faq__new_q_and_a (integer,integer,varchar,varchar,integer,varchar,timestamptz,integer,varchar,integer
    	) returns integer as
'
declare
	p_entry_id   		alias for $1;				-- default null,
	p_faq_id     		alias for $2;
	p_question   		alias for $3;
	p_answer     		alias for $4;
	p_sort_key   		alias for $5;
	p_object_type 	alias for $6;     		-- default faq_q_and_a
	p_creation_date alias for $7;  --in acs_objects.creation_date%TYPE   default sysdate,
	p_creation_user alias for $8;	 --in acs_objects.creation_user%TYPE   default null,
	p_creation_ip    	alias for $9;		-- in acs_objects.creation_ip%TYPE     default null,
	p_context_id     	alias for $10; 	--in acs_objects.context_id%TYPE      default null
	v_entry_id 			faq_q_and_as.entry_id%TYPE;
begin
	v_entry_id := acs_object__new (
		p_entry_id,
		p_object_type,		
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
  );
	insert into faq_q_and_as
		(entry_id, faq_id, question, answer, sort_key)
	values
		(v_entry_id, p_faq_id, p_question, p_answer, p_sort_key);
  return v_entry_id;

end;' language 'plpgsql';

create function  faq__delete_q_and_a (integer)
returns integer as '
declare
	p_entry_id	alias for $1;
begin
	delete from faq_q_and_as where entry_id =  p_entry_id;
	raise NOTICE ''Deleting FAQ_Q_and_A...'';
	PERFORM acs_object__delete(p_entry_id);

	return 0;

end;' language 'plpgsql';


create function faq__new_faq (integer, varchar, boolean,varchar,timestamptz,integer,varchar,integer )
returns integer as '
declare
	p_faq_id				alias for $1;
	p_faq_name 			alias for $2;
	p_separate_p		alias for $3;
	p_object_type 	alias for $4;
	p_creation_date	alias for $5;
	p_creation_user alias for $6;
	p_creation_ip		alias for $7;
	p_context_id 		alias for $8;
	v_faq_id 				faqs.faq_id%TYPE;
begin

	v_faq_id := acs_object__new (
		p_faq_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
  );

	insert into faqs
		(faq_id, faq_name,separate_p)
	values
		(v_faq_id, p_faq_name,p_separate_p);

return v_faq_id;

end;' language 'plpgsql';


create function faq__delete_faq (integer)
returns integer as '
declare
	p_faq_id 	alias for $1;
	del_rec record;
begin
	   	-- Because q_and_as are objects, we need to
    	-- loop through a list of them, and call an explicit
    	-- delete function for each one. (i.e. each
    	-- entry_id)
	for del_rec in select entry_id from faq_q_and_as
		where faq_id = p_faq_id
  loop
		PERFORM faq__delete_q_and_a(del_rec.entry_id);
	end loop;
	
	delete from faqs where faq_id = p_faq_id;
	
	PERFORM  acs_object__delete(p_faq_id);

	return 0;

end;' language 'plpgsql';

create function faq__name(integer)
returns varchar as '
declare 
    p_faq_id      alias for $1;
    v_faq_name    faqs.faq_name%TYPE;
begin
	select faq_name  into v_faq_name
		from faqs
		where faq_id = p_faq_id;

    return v_faq_name;
end;
' language 'plpgsql';

create function faq__clone (integer,integer)
returns integer as '
declare
 p_new_package_id  	alias for $1;   --default null,
 p_old_package_id 	alias for $2;   --default null
 v_faq_id 		faqs.faq_id%TYPE;
 one_faq		record;
 entry			record;

begin
            -- get all the faqs belonging to the old package,
            -- and create new faqs for the new package
            for one_faq in select *
                            from acs_objects o, faqs f
                            where o.object_id = f.faq_id
                            and o.context_id = p_old_package_id
            loop
               v_faq_id := faq__new_faq (
                    			one_faq.faq_name,
                    			one_faq.separate_p,
                    			p_new_package_id
               	);

           	for entry in select * from faq_q_and_as
                                   where faq_id = one_faq.faq_id
           	loop

           		perform  faq__new_q_and_a (
                       		entry.faq_id,
                       		v_faq_id,
                       		entry.question,
                       		entry.answer,
                       		entry.sort_key
           	);
               end loop;
           end loop;
 return 0;
 end;
' language 'plpgsql';



 select acs_privilege__create_privilege('faq_view_faq');
 select acs_privilege__create_privilege('faq_create_faq');
 select acs_privilege__create_privilege('faq_delete_faq');
 select acs_privilege__create_privilege('faq_modify_faq');
 select acs_privilege__create_privilege('faq_view_q_and_a');
 select acs_privilege__create_privilege('faq_create_q_and_a');
 select acs_privilege__create_privilege('faq_delete_q_and_a');
 select acs_privilege__create_privilege('faq_modify_q_and_a');
 select acs_privilege__create_privilege('faq_admin_faq');
 select acs_privilege__create_privilege('faq_admin_q_and_a');
 select acs_privilege__add_child('faq_admin_faq', 'faq_view_faq');
 select acs_privilege__add_child('faq_admin_faq', 'faq_create_faq');
 select acs_privilege__add_child('faq_admin_faq', 'faq_delete_faq');
 select acs_privilege__add_child('faq_admin_faq', 'faq_modify_faq');
 select acs_privilege__add_child('faq_admin_q_and_a', 'faq_view_q_and_a');
 select acs_privilege__add_child('faq_admin_q_and_a', 'faq_create_q_and_a');
 select acs_privilege__add_child('faq_admin_q_and_a', 'faq_delete_q_and_a');
 select acs_privilege__add_child('faq_admin_q_and_a', 'faq_modify_q_and_a');
 select acs_privilege__add_child('faq_admin_faq', 'faq_admin_q_and_a');

 -- bind privileges to global names

 select acs_privilege__add_child('create','faq_create_faq');
 select acs_privilege__add_child('create','faq_create_q_and_a');
 select acs_privilege__add_child('write','faq_modify_faq');
 select acs_privilege__add_child('write','faq_modify_q_and_a');
 select acs_privilege__add_child('read','faq_view_faq');
 select acs_privilege__add_child('read','faq_view_q_and_a');
 select acs_privilege__add_child('delete','faq_delete_faq');
 select acs_privilege__add_child('delete','faq_delete_q_and_a');
 select acs_privilege__add_child('admin','faq_admin_faq');


create function inline_2 ()
returns integer as '
declare
	default_context 	acs_objects.object_id%TYPE;
	registered_users 	acs_objects.object_id%TYPE;
	the_public 				acs_objects.object_id%TYPE;
begin

  default_context = acs__magic_object_id(''default_context'');
  registered_users = acs__magic_object_id(''registered_users'');
  the_public = acs__magic_object_id(''the_public'');

  -- give the public the power to view faqs by default

  PERFORM acs_permission__grant_permission (default_context, the_public, ''faq_view_faq'');


  -- give the public the power to view q_and_as by default

  PERFORM acs_permission__grant_permission ( default_context,the_public, ''faq_view_q_and_a'');
  			
  return 0;

end;' language 'plpgsql';


select inline_2 ();

drop function inline_2 ();








