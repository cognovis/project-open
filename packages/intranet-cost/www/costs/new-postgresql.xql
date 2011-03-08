<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-cost/www/costs/new-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-22 -->
<!-- @arch-tag 7410be05-735d-4f4d-b0e5-6252f93a9d29 -->
<!-- @cvs-id $Id: new-postgresql.xql,v 1.2 2004/09/24 16:05:46 cvs Exp $ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="cost_insert">
    <querytext>
      select im_cost__new (
                null,           -- cost_id
                'im_cost',      -- object_type
                now(),          -- creation_date
                :user_id,       -- creation_user
                '[ad_conn peeraddr]', -- creation_ip
                null,           -- context_id
      
                :cost_name,     -- cost_name
                null,           -- parent_id
		:project_id,    -- project_id
                :customer_id,    -- customer_id
                :provider_id,   -- provider_id
                null,           -- investment_id

                :cost_status_id, -- cost_status_id
                :cost_type_id,  -- cost_type_id
                :template_id,   -- template_id
      
                :effective_date, -- effective_date
                :payment_days,  -- payment_days
		:amount,        -- amount
                :currency,      -- currency
                :vat,           -- vat
                :tax,           -- tax

                'f',            -- variable_cost_p
                'f',            -- needs_redistribution_p
                'f',            -- redistributed_p
                'f',            -- planning_p
                null,           -- planning_type_id

                :description,   -- description
                :note           -- note
      )
    </querytext>
  </fullquery>
</queryset>
