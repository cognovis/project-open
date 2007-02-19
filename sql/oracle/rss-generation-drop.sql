declare
    v_result	    integer;
    v_delete        integer;
begin

   select MAX(subscr_id) into v_result from rss_gen_subscrs;
   While (v_result > 0) loop
   	v_delete := rss_gen_subscr.del(
		p_subscr_id => v_result
  	);
	select MAX(subscr_id) into v_result from rss_gen_subscrs;
   End loop;

   acs_rel_type.drop_type('rss_gen_subscr','f');

end;
/
show errors

drop table rss_gen_subscrs;
drop package rss_gen_subscr;
