
-- Get everything from a Cost Center
        select  cc.*
        from    im_cost_centers cc
        where   cc.cost_center_id = :cost_center_id
;


-- Create a new Cost Center
        PERFORM im_cost_center__new (
                null,                   -- cost_center_id
                'im_cost_center',       -- object_type
                now(),                  -- creation_date
                null,                   -- creation_user
                null,                   -- creation_ip
                null,                   -- context_id

                :cost_center_name,
                :cost_center_label,
                :cost_center_code,
                :cost_center_type_id,
                :cost_center_status_id,
                :parent_id,
                :manager_id,
                :department_p,
                :description,
                :note
        )
;


-- Update a Cost Center
        update im_cost_centers set
                cost_center_name        = :cost_center_name,
                cost_center_label       = :cost_center_label,
                cost_center_code        = :cost_center_code,
                cost_center_type_id     = :cost_center_type_id,
                cost_center_status_id   = :cost_center_status_id,
                department_p            = :department_p,
                parent_id               = :parent_id,
                manager_id              = :manager_id,
                description             = :description
        where
                cost_center_id = :cost_center_id
;


-- Delete a Cost Center

PERFORM im_cost_center__delete(:cost_center_id);



-- Get a list of all Cost Items visible for the current user,
-- together with customer, provider and project (if associated
-- 1:1).
-- Cost Center permissions are set per cost_type_id (different
-- for quote, invoice, ...)

select
	c.*,
	o.object_type,
	url.url as cost_url,
	ot.pretty_name as object_type_pretty_name,
	cust.company_name as customer_name,
	cust.company_path as customer_short_name,
	proj.project_nr,
	prov.company_name as provider_name,
	prov.company_path as provider_short_name,
	im_category_from_id(c.cost_status_id) as cost_status,
	im_category_from_id(c.cost_type_id) as cost_type,
	now()::date - c.effective_date::date + c.payment_days::integer as overdue
	$extra_select
from
	im_costs c 
	LEFT JOIN
	   im_projects proj ON c.project_id = proj.project_id,
	acs_objects o,
	acs_object_types ot,
	im_companies cust,
	im_companies prov,
	(select * from im_biz_object_urls where url_type=:view_mode) url,
	(       select  cc.cost_center_id,
			ct.cost_type_id
		from    im_cost_centers cc,
			im_cost_types ct,
			acs_permissions p,
			party_approved_member_map m,
			acs_object_context_index c,
			acs_privilege_descendant_map h
		where
			p.object_id = c.ancestor_id
			and h.descendant = ct.read_privilege
			and c.object_id = cc.cost_center_id
			and m.member_id = :user_id
			and p.privilege = h.privilege
			and p.grantee_id = m.party_id
	) cc
	$extra_from
where
	c.customer_id=cust.company_id
	and c.provider_id=prov.company_id
	and c.cost_id = o.object_id
	and o.object_type = url.object_type
	and o.object_type = ot.object_type
	and c.cost_center_id = cc.cost_center_id
	and c.cost_type_id = cc.cost_type_id
	$company_where
	$where_clause
	$extra_where
	$order_by_clause


-- Update a Cost Item
        update  im_costs set
                cost_name               = :cost_name,
                project_id              = :project_id,
                customer_id             = :customer_id,
                provider_id             = :provider_id,
                cost_center_id          = :cost_center_id,
                cost_status_id          = :cost_status_id,
                cost_type_id            = :cost_type_id,
                template_id             = :template_id,
                effective_date          = :effective_date,
                start_block             = :start_block,
                payment_days            = :payment_days,
                amount                  = :amount,
                paid_amount             = :paid_amount,
                currency                = :currency,
                paid_currency           = :paid_currency,
                vat                     = :vat,
                tax                     = :tax,
                cause_object_id         = :cause_object_id,
                description             = :description,
                note                    = :note
        where
                cost_id = :cost_id


-- Update only the status of a Cost Item
update im_costs 
set cost_status_id=:cost_status_id 
where cost_id = :cost_id
;




-- Delete a Cost Item
-- We have to call different destructors depending on the 
-- actual type of the cost (im_cost, im_invoice, im_expense, ...)
-- $otype contains the object type from a previous query.
--
PERFORM ${otype}__delete(:cost_id)


-- Create a new (basic!) cost Item
-- Don't use this for cost items of derived types such as
-- im_invoice, im_expense etc.
--
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



-- Relationship between Costs and Projects:
-- Select all the cost items "related" to a project
-- and its subprojects (?!?).
--
select	c.*
from	im_costs c
where
    c.cost_id in (
        select distinct cost_id
        from im_costs
        where project_id = :project_id
    UNION
        select distinct cost_id
        from im_costs
        where parent_id = :project_id
    UNION
        select distinct object_id_two as cost_id
        from acs_rels
        where object_id_one = :project_id
    UNION
        select distinct object_id_two as cost_id
        from acs_rels r, im_projects p
        where object_id_one = p.project_id
              and p.parent_id = :project_id
    )

