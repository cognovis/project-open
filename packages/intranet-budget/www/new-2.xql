<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


   <fullquery name="insert_cost">
     <querytext>
       SELECT im_cost__new(
       null,              -- cost_id
       'im_cost',         -- im_cost
       now(),            -- creation_date
       :user_id,          -- creation_user
       :creation_ip,      -- creation_ip
       null,              -- context_id
       :cost_name,        -- cost_name
       null,              -- parent_id
       :project_id,       -- project_id
       :customer_id,      -- customer_id
       :provider_id,      -- provider_id
       null,              -- investment_id
       :cost_status_id,   -- cost_status_id
       :cost_type_id,     -- cost_type
       null,              -- template_id
       null,              -- efective_date
       null,              -- payment_days
       null,              -- amount
       'EUR',             -- currency
       0,                 -- vat
       0,                 -- tax
       null,              -- variable_cost_p
       null,              -- needs_redistribution_p
       null,              -- redistributed_p
       null,              -- planning_p
       null,              -- planning_type_id
       null,              -- note
       null               -- description
       );
       
     </querytext>
   </fullquery>

   <fullquery name="insert_cost_item">
     <querytext>
       SELECT im_cost__new(
       null,              -- cost_id
       'im_cost',         -- im_cost
       now(),            -- creation_date
       :user_id,          -- creation_user
       :creation_ip,      -- creation_ip
       null,              -- context_id
       :name,             -- cost_name
       :parent_cost_id,    -- parent_id
       :project_id,       -- project_id
       :customer_id,      -- customer_id
       :provider_id,      -- provider_id
       null,              -- investment_id
       :cost_status_id,   -- cost_status_id
       :cost_type_id,     -- cost_type
       null,              -- template_id
       null,              -- efective_date
       null,              -- payment_days
       :amount,           -- amount
       :currency,         -- currency
       0,                 -- vat
       0,                 -- tax
       null,              -- variable_cost_p
       null,              -- needs_redistribution_p
       null,              -- redistributed_p
       null,              -- planning_p
       null,              -- planning_type_id
       null,              -- note
       null               -- description
       );
       
     </querytext>
   </fullquery>

</queryset>
