------------------------------------------------------------
-- Costs
------------------------------------------------------------

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
	(       select distinct
			cc.cost_center_id,
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
	$order_by_clause;


-- Update a Cost Item
update  im_costs set
	cost_name		= :cost_name,
	project_id		= :project_id,
	customer_id		= :customer_id,
	provider_id		= :provider_id,
	cost_center_id		= :cost_center_id,
	cost_status_id		= :cost_status_id,
	cost_type_id		= :cost_type_id,
	template_id		= :template_id,
	effective_date		= :effective_date,
	start_block		= :start_block,
	payment_days		= :payment_days,
	amount			= :amount,
	paid_amount		= :paid_amount,
	currency		= :currency,
	paid_currency		= :paid_currency,
	vat			= :vat,
	tax			= :tax,
	cause_object_id		= :cause_object_id,
	description	   	= :description,
	note		   	= :note
where
	cost_id = :cost_id;


-- Update only the status of a Cost Item
update	im_costs 
set	cost_status_id=:cost_status_id 
where	cost_id = :cost_id;


-- Delete a Cost Item
-- We have to call different destructors depending on the 
-- actual type of the cost (im_cost, im_invoice, im_expense, ...)
-- $otype contains the object type from a previous query.
--
PERFORM ${otype}__delete(:cost_id)



-- Exchange Rates:
-- Invoices and Cost Items are stored together with their original
-- currency to avoid any rounding errors etc.
-- In order to calculate a sum of invoices you have to use the
-- Exchange Rates module:
--
select im_exchange_rate(to_date('2005-07-01','YYYY-MM-DD'), 'EUR', 'USD');


-- Create a new (basic!) cost Item
-- Don't use this for cost items of derived types such as
-- im_invoice, im_expense etc.
--
select im_cost__new (
	null,			-- cost_id
	'im_cost',		-- object_type
	now(),			-- creation_date
	:user_id,		-- creation_user
	'[ad_conn peeraddr]',	-- creation_ip
	null,			-- context_id
	  
	:cost_name,		-- cost_name
	null,			-- parent_id
	:project_id,		-- project_id
	:customer_id,		-- customer_id
	:provider_id,		-- provider_id
	null,			-- investment_id

	:cost_status_id,	-- cost_status_id
	:cost_type_id,  	-- cost_type_id
	:template_id,		-- template_id
	  
	:effective_date,	-- effective_date
	:payment_days,  	-- payment_days
	:amount,		-- amount
	:currency,		-- currency
	:vat,			-- vat
	:tax,			-- tax

	'f',			-- variable_cost_p
	'f',			-- needs_redistribution_p
	'f',			-- redistributed_p
	'f',			-- planning_p
	null,			-- planning_type_id

	:description,		-- description
	:note			-- note
);



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
;

-- Check if there is already a relation between a project
-- and a cost item:
select
	count(*) as v_rel_exists
from	acs_rels
where	object_id_one = :project_id
	and object_id_two = :invoice_id;


-------------------------------------------------------------
-- Costs
--
-- Costs is the superclass for all financial items such as 
-- Invoices, Quotes, Purchase Orders, Bills (from providers), 
-- Travel Costs, Payroll Costs, Fixed Costs, Amortization Costs,
-- etc. in order to allow for simple SQL queries revealing the
-- financial status of a company.
--
-- Costs are also used for controlling, namely by assigning costs
-- to projects, companies and cost centers in order to allow for 
-- (more or less) accurate profit & loss calculation.
-- This assignment sometimes requires to split a large cost item
-- into several smaller items in order to assign them more 
-- accurately to project, companies or cost centers ("redistribution").
--
-- Costs reference acs_objects for customer and provider in order to
-- allow costs to be created for example between an employee and the
-- company in the case of travel costs.
--

create table im_costs (
	cost_id			integer
				constraint im_costs_pk
				primary key
				constraint im_costs_cost_fk
				references acs_objects,
	-- force a name because we may want to use object.name()
	-- later to list cost
	cost_name		varchar(400)
				constraint im_costs_name_nn
				not null,
	-- Nr is a current number to provide a unique 
	-- identifier of a cost item for backup/restore.
	cost_nr			varchar(400)
				constraint im_costs_nr_nn
				not null,
	project_id		integer
				constraint im_costs_project_fk
				references im_projects,
				-- who pays?
	customer_id		integer
				constraint im_costs_customer_nn
				not null
				constraint im_costs_customer_fk
				references acs_objects,
				-- who gets paid?
	cost_center_id		integer
				constraint im_costs_cost_center_fk
				references im_cost_centers,
	provider_id		integer
				constraint im_costs_provider_nn
				not null
				constraint im_costs_provider_fk
				references acs_objects,
	investment_id		integer
				constraint im_costs_inv_fk
				references acs_objects,
	cost_status_id		integer
				constraint im_costs_status_nn
				not null
				constraint im_costs_status_fk
				references im_categories,
	cost_type_id		integer
				constraint im_costs_type_nn
				not null
				constraint im_costs_type_fk
				references im_categories,
	-- reference to an object that has caused this cost,
	-- in particular to im_repeating_costs
	cause_object_id		integer
				constraint im_costs_cause_fk
				references acs_objects,
	template_id		integer
				constraint im_cost_template_fk
				references im_categories,
	-- when does the invoice start to be valid?
	-- due_date is effective_date + payment_days.
	effective_date		timestamptz,
	-- start_blocks are the first days every month. This allows
	-- for fast monthly grouping
	start_block		timestamptz
				constraint im_costs_startblck_fk
				references im_start_months,
	payment_days		integer,
	-- amount=null means calculated amount, for example
	-- with an invoice
	amount			numeric(12,3),
	currency		char(3) 
				constraint im_costs_currency_fk
				references currency_codes(iso),
	paid_amount		numeric(12,3),
	paid_currency		char(3) 
				constraint im_costs_paid_currency_fk
				references currency_codes(iso),
	-- % of total price is VAT
	vat			numeric(12,5) default 0,
	-- % of total price is TAX
	tax			numeric(12,5) default 0,
	-- Classification of variable against fixed costs
	variable_cost_p		char(1)
				constraint im_costs_var_ck
				check (variable_cost_p in ('t','f')),
	needs_redistribution_p	char(1)
				constraint im_costs_needs_redist_ck
				check (needs_redistribution_p in ('t','f')),
	-- Points to its parent if the parent was distributed
	parent_id		integer
				constraint im_costs_parent_fk
				references im_costs,
	-- Indicates that this cost has been redistributed to
	-- potentially several other costs, so we don't want to
	-- include this item in sums.
	redistributed_p		char(1)
				constraint im_costs_redist_ck
				check (redistributed_p in ('t','f')),
	planning_p		char(1)
				constraint im_costs_planning_ck
				check (planning_p in ('t','f')),
	planning_type_id	integer
				constraint im_costs_planning_type_fk
				references im_categories,
	description		text,
	note			text
);
