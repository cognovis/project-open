<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="rss_gen_service.timed_out_subscriptions">      
    <querytext>
        select r.subscr_id,
               r.timeout,
               r.summary_context_id,
               i.impl_name,
               nvl2(r.lastbuild, (r.lastbuild-to_date('1970-01-01'))*60*60*24, 0) as lastbuild
        from rss_gen_subscrs r,
             acs_sc_impls i
        where i.impl_id = r.impl_id
          and (r.lastbuild is null
               or sysdate > r.lastbuild + r.timeout/(60*60*24))
    </querytext>
  </fullquery>

  <fullquery name="rss_gen_report.update_timestamp">  
    <querytext>
        update rss_gen_subscrs
        set lastbuild = sysdate,
            last_ttb = :last_ttb $extra_sql
            where subscr_id = :subscr_id
    </querytext>
  </fullquery>

  <fullquery name="rss_gen_bind.get_contract_id">      
    <querytext>
	select acs_sc_contract.get_id('RssGenerationSubscriber') from dual
    </querytext>
  </fullquery>


  <fullquery name="rss_gen_bind.get_unbound_impls">  
    <querytext>
        select impl_id
        from acs_sc_impls i
        where impl_contract_name = 'RssGenerationSubscriber'
          and not exists (select 1
                          from acs_sc_bindings b
                          where b.impl_id = i.impl_id
                            and b.contract_id = :contract_id)
    </querytext>
  </fullquery>

  <fullquery name="rss_gen_bind.bind_impl">
    <querytext>
         begin  
             acs_sc_binding.new(
                 contract_id => $contract_id,
                impl_id => $impl_id
             );
         end;
    </querytext>
  </fullquery>

</queryset>
