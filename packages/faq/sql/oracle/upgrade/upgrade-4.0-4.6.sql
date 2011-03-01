-- faq upgrade script
-- @author Vinod Kurup (vinod@kurup.com)
-- @creation-date 2002-10-27

-- new procedure 'clone'

create or replace package faq 
as

	function new_faq (
	        faq_id        in faqs.faq_id%TYPE                 default null,
		faq_name      in faqs.faq_name%TYPE,
		separate_p    in faqs.separate_p%TYPE	  	  default 'f',
		object_type   in acs_objects.object_type%TYPE     default 'faq',
		creation_date in acs_objects.creation_date%TYPE   default sysdate,
		creation_user in acs_objects.creation_user%TYPE   default null,
		creation_ip   in acs_objects.creation_ip%TYPE     default null,
		context_id    in acs_objects.context_id%TYPE      default null
        ) return acs_objects.object_id%TYPE;



	procedure delete_faq (
		 faq_id in faqs.faq_id%TYPE
        );


	function new_q_and_a (
	        entry_id      in faq_q_and_as.entry_id%TYPE       default null,
                faq_id        in faq_q_and_as.faq_id%TYPE,
	        question      in faq_q_and_as.question%TYPE,
                answer        in faq_q_and_as.answer%TYPE,
		sort_key      in faq_q_and_as.sort_key%TYPE,       
		object_type   in acs_objects.object_type%TYPE     default 'faq_q_and_a',
		creation_date in acs_objects.creation_date%TYPE   default sysdate,
		creation_user in acs_objects.creation_user%TYPE   default null,
		creation_ip   in acs_objects.creation_ip%TYPE     default null,
		context_id    in acs_objects.context_id%TYPE      default null
        ) return acs_objects.object_id%TYPE;



	procedure delete_q_and_a (
		  entry_id in faq_q_and_as.entry_id%TYPE
        );


	procedure clone (
          old_package_id    in apm_packages.package_id%TYPE,
          new_package_id    in apm_packages.package_id%TYPE
        );


end faq;
/
show errors




create or replace package body faq 
as
    	function new_q_and_a (
	        entry_id      in faq_q_and_as.entry_id%TYPE       default null,
                faq_id        in faq_q_and_as.faq_id%TYPE,
	        question      in faq_q_and_as.question%TYPE,
                answer        in faq_q_and_as.answer%TYPE,
		sort_key      in faq_q_and_as.sort_key%TYPE,       
		object_type   in acs_objects.object_type%TYPE     default 'faq_q_and_a',
		creation_date in acs_objects.creation_date%TYPE   default sysdate,
		creation_user in acs_objects.creation_user%TYPE   default null,
		creation_ip   in acs_objects.creation_ip%TYPE     default null,
		context_id    in acs_objects.context_id%TYPE      default null
    	) return acs_objects.object_id%TYPE
    	is
		v_entry_id faq_q_and_as.entry_id%TYPE;
   	begin
		v_entry_id := acs_object.new (
		object_id => entry_id,
		object_type => object_type,		
		creation_date => creation_date,
		creation_user => creation_user,
		creation_ip => creation_ip,
		context_id => context_id
    	);
    	insert into faq_q_and_as
	   	(entry_id, faq_id, question, answer, sort_key)
    	values
	   	(v_entry_id, new_q_and_a.faq_id, new_q_and_a.question, new_q_and_a.answer, new_q_and_a.sort_key);

    	return v_entry_id;
    	end new_q_and_a;




    	procedure delete_q_and_a (
		entry_id	in faq_q_and_as.entry_id%TYPE 
    	)
    	is		
   	begin
		delete from faq_q_and_as where entry_id =  faq.delete_q_and_a.entry_id;
		acs_object.delete(entry_id);
   	end delete_q_and_a;




    	function new_faq (
	        faq_id     in faqs.faq_id%TYPE                  default null,
		faq_name in faqs.faq_name%TYPE,
		separate_p    in faqs.separate_p%TYPE	  	default 'f',
		object_type in acs_objects.object_type%TYPE     default 'faq',
		creation_date in acs_objects.creation_date%TYPE default sysdate,
		creation_user in acs_objects.creation_user%TYPE default null,
		creation_ip in acs_objects.creation_ip%TYPE     default null,
		context_id in acs_objects.context_id%TYPE       default null
    	) return acs_objects.object_id%TYPE
    	is
		v_faq_id faqs.faq_id%TYPE;
    	begin

		v_faq_id := acs_object.new (
		object_id => faq_id,
		object_type => object_type,
		creation_date => creation_date,
		creation_user => creation_user,
		creation_ip => creation_ip,
		context_id => context_id
    	);
    	insert into faqs
	        (faq_id, faq_name,separate_p)
    	values
		(v_faq_id, new_faq.faq_name,new_faq.separate_p);

    	return v_faq_id;
    	end new_faq;


    	procedure delete_faq (
		faq_id faqs.faq_id%TYPE
    	)
    	is
    	begin

    	-- Because q_and_a's are objects, we need to
    	-- loop through a list of them, and call an explicit
    	-- delete function for each one. (i.e. each
    	-- entry_id)

	 declare cursor q_and_a_cur is
	 select entry_id from faq_q_and_as where faq_id = faq.delete_faq.faq_id;
	 begin
	 for entry_list in q_and_a_cur 
	 loop
	 delete_q_and_a(entry_list.entry_id);
	 end loop;
	 end;
  
		delete from faqs where faq_id=faq.delete_faq.faq_id;
		acs_object.delete(faq_id);

     	end delete_faq;


	procedure clone (
          old_package_id    in apm_packages.package_id%TYPE   default null,
          new_package_id    in apm_packages.package_id%TYPE   default null
        )
        is
            v_faq_id faqs.faq_id%TYPE;
            v_entry_id faq_q_and_as.entry_id%TYPE;
        begin
            -- get all the faqs belonging to the old package,
            -- and create new faqs for the new package
            for one_faq in (select * 
                            from acs_objects o, faqs f
                            where o.object_id = f.faq_id
                            and o.context_id = faq.clone.old_package_id)
            loop
            
                -- faq is "scoped" by using the acs_objects.context_id
                v_faq_id := faq.new_faq (
                    faq_name     => one_faq.faq_name,      
                    separate_p   => one_faq.separate_p,
                    context_id   => faq.clone.new_package_id                    
               );                                      
               
               for entry in (select * from faq_q_and_as f
                                   where faq_id = one_faq.faq_id)
               loop
                   -- now (surprise!) copy all the entries of this faq
                   v_entry_id :=  faq.new_q_and_a (
                       context_id => entry.faq_id,
                       faq_id=> v_faq_id,
                       question => entry.question,
                       answer => entry.answer,
                       sort_key => entry.sort_key
                   );
               end loop;
           end loop;
        end clone;


end faq;
/
show errors


-- disabled_p added to faqs

alter table faqs add (disabled_p char(1) default 'f' check(disabled_p in ('f','t')));
