create or replace function faq__clone (integer,integer)
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


alter table faqs add column disabled_p char(1);
alter table faqs alter disabled_p set default 'f';
alter table faqs add constraint faqs_disabled_p_ck check (disabled_p in ('t','f'));

