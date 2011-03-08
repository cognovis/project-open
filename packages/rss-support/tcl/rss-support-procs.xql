<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN"
"http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Dave Bauer (dave@thedesignexperience.org) -->
<!-- @creation-date 2005-01-23 -->
<!-- @arch-tag: d73e6747-bd1d-4b7d-a9fc-517631646e05 -->
<!-- @cvs-id $Id: rss-support-procs.xql,v 1.2 2005/02/24 13:33:25 jeffd Exp $ -->

<queryset>
  <fullquery
    name="rss_support::subscription_exists.subscription_exists">
    <querytext>
      select 1 from rss_gen_subscrs r,acs_sc_impls a
      where r.summary_context_id=:summary_context_id
      and a.impl_name=:impl_name
      and a.impl_id=r.impl_id
    </querytext>
  </fullquery>

  <fullquery name="rss_support::add_subscription.get_impl_id">
    <querytext>
      select impl_id
      from acs_sc_impls
      where impl_name=:impl_name
      and impl_contract_name='RssGenerationSubscriber'
      and impl_owner_name=:owner
    </querytext>
  </fullquery>

  <fullquery name="rss_support::get_subscr_id.get_impl_id">
    <querytext>
      select impl_id
      from acs_sc_impls
      where impl_name=:impl_name
      and impl_contract_name='RssGenerationSubscriber'
      and impl_owner_name=:owner
    </querytext>
  </fullquery>
  
  <fullquery name="rss_support::get_subscr_id.get_subscr_id">
    <querytext>
      select subscr_id
      from rss_gen_subscrs
      where impl_id=:impl_id
      and summary_context_id=:summary_context_id
    </querytext>
  </fullquery>
  
</queryset>
