<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-expense/www/bundle-create-postgresql.xql -->
<!-- @author  (avila@digiteix.com) -->
<!-- @creation-date 2006-04-27 -->
<!-- @arch-tag 7410be05-735d-4f4d-b0e5-6252f93a9d29 -->
<!-- @cvs-id $Id: bundle-create-postgresql.xql,v 1.5 2008/02/15 12:01:50 cambridge Exp $ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="create_expense_bundle">
    <querytext>
      select im_cost__new (
		null,			-- cost_id
		'im_expense_bundle',	-- object_type
		now(),			-- creation_date
		:provider_id,		-- creation_user
		'[ad_conn peeraddr]',	-- creation_ip
		null,			-- context_id
      
		:cost_name,     	-- cost_name
		null,			-- parent_id
		:common_project_id,    	-- project_id
		:customer_id,		-- customer_id
		:provider_id,		-- provider_id
		null,			-- investment_id

		:cost_status_id,	-- cost_status_id
		:cost_type_id,		-- cost_type_id
		:template_id,		-- template_id
      
		now(),			-- effective_date
		:payment_days,  	-- payment_days
		:amount_before_vat,	-- amount
		:default_currency,	-- currency
		:bundle_vat,		-- vat
		:tax,			-- tax

		'f',			-- variable_cost_p
		'f',			-- needs_redistribution_p
		'f',			-- redistributed_p
		'f',			-- planning_p
		null,			-- planning_type_id

		:description,   	-- description
		:note			-- note
      )
    </querytext>
  </fullquery>
</queryset>
