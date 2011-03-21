<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-cost/www/costs/new-oracle.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-22 -->
<!-- @arch-tag bf5f9d3f-3268-4449-8cbe-c27c6e6e0b2b -->
<!-- @cvs-id $Id: new-oracle.xql,v 1.2 2004/09/24 16:05:46 cvs Exp $ -->

<queryset>
  
  
  <rdbms>
    <type>oracle</type>
    <version>8.1.6</version>
  </rdbms>
  
  <fullquery name = "cost_insert">
    <querytext>
        1 := im_cost.new (
                cost_id         => :cost_id,
                creation_user   => :user_id,
                creation_ip     => '[ad_conn peeraddr]',
                cost_name       => :cost_name,
		project_id	=> :project_id,
                customer_id     => :customer_id,
                provider_id     => :provider_id,
                cost_status_id  => :cost_status_id,
                cost_type_id    => :cost_type_id,
                template_id     => :template_id,
                effective_date  => :effective_date,
                payment_days    => :payment_days,
		amount		=> :amount,
                currency        => :currency,
                vat             => :vat,
                tax             => :tax,
                description     => :description,
                note            => :note
        );
    </querytext>
  </fullquery>
</queryset>
