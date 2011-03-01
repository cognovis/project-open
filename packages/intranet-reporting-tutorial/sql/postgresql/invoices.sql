------------------------------------------------------------
-- Invoices
------------------------------------------------------------

-- Get information about a single invoice.
-- Please note that this only returns a value for project if there
-- is exactly ONE project associated with the invoice.
select
	i.*,
	p.*,
	im_category_from_id(i.item_type_id) as item_type,
	im_category_from_id(i.item_uom_id) as item_uom,
	p.project_nr as project_short_name,
	round(i.price_per_unit * i.item_units * :rf) / :rf as amount,
	to_char(round(i.price_per_unit * i.item_units * :rf) / :rf, :cur_format) as amount_formatted
from
	im_invoice_items i
	      LEFT JOIN im_projects p on i.project_id = p.project_id
where
	i.invoice_id = :invoice_id
;



-- Get a list of all invoices (no permissions applied)
select
	i.*,
	ci.*,
	c.*,
	to_date(to_char(i.invoice_date,'YYYY-MM-DD'),'YYYY-MM-DD') + i.payment_days 
		as calculated_due_date,
	im_cost_center_name_from_id(ci.cost_center_id) as cost_center_name,
	im_category_from_id(ci.cost_status_id) as cost_status,
	im_category_from_id(ci.cost_type_id) as cost_type,
	im_category_from_id(ci.template_id) as template
from
	im_invoices_active i,
	im_costs ci,
	im_companies c
where
	i.invoice_id=:invoice_id
	and ci.cost_id = i.invoice_id
	and i.customer_id = c.company_id
;


-- Get the list of invoices visible for the current user
-- (Cost Center permission restrictions):
select
	i.*,
	(to_date(to_char(i.invoice_date,:date_format),:date_format) + i.payment_days) 
		as due_date_calculated,
	o.object_type,
	to_char(ci.amount,:cur_format) as invoice_amount_formatted,
	im_email_from_user_id(i.company_contact_id) as company_contact_email,
	im_name_from_user_id(i.company_contact_id) as company_contact_name,
	c.company_name as customer_name,
	c.company_path as company_short_name,
	p.company_name as provider_name,
	p.company_path as provider_short_name,
	im_category_from_id(i.invoice_status_id) as invoice_status,
	im_category_from_id(i.cost_type_id) as cost_type
from
	im_invoices_active i,
	im_costs ci,
	acs_objects o,
	im_companies c,
	im_companies p,
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
			and ct.cost_type_id = :source_cost_type_id
	) readable_ccs
where
	i.invoice_id = o.object_id
	and i.invoice_id = ci.cost_id
	and i.customer_id = c.company_id
	and i.provider_id = p.company_id
	and ci.cost_type_id = :source_cost_type_id
	and ci.cost_center_id = readable_ccs.cost_center_id
	$project_where_clause
$order_by_clause


-- Exchange Rates:
-- Invoices and Cost Items are stored together with their original
-- currency to avoid any rounding errors etc.
-- In order to calculate a sum of invoices you have to use the
-- Exchange Rates module:
--
select im_exchange_rate(to_date('2005-07-01','YYYY-MM-DD'), 'EUR', 'USD');



-- Calculate the invoice total from the invoice items.
-- Please note the way rounding is handled: Each invoice
-- item is rounded first, and then the total is calculated
-- from the sum of the rouned items.
-- 
select
	max(i.currency) as currency,
	sum(i.amount) as subtotal,
	round(sum(i.amount) * :vat / 100 * :rf) / :rf as vat_amount,
	round(sum(i.item_units * i.price_per_unit) * :tax / 100 * :rf) / :rf as tax_amount,
	round(  sum(i.amount) * :rf) / :rf +
		round(sum(i.amount) * :vat / 100 * :rf) / :rf +
		round(sum(i.amount) * :tax / 100 * :rf) / :rf as grand_total
from (
	select
		i.*,
		round(i.price_per_unit * i.item_units * :rf) / :rf as amount
	from
		im_invoice_items i
	where
		i.invoice_id = :invoice_id
      ) i
;


-- Update an Invoice.
-- Invoice fields are found in the table im_costs
-- (base information) and im_invoices, so you need
-- two update statements.
--
update im_invoices
set
	invoice_nr      = :invoice_nr,
	payment_method_id = :payment_method_id,
	company_contact_id = :company_contact_id,
	invoice_office_id = :invoice_office_id
where
	invoice_id = :invoice_id
;

update im_costs
set
	project_id      = :project_id,
	cost_name       = :invoice_nr,
	customer_id     = :customer_id,
	cost_nr	 = :invoice_id,
	provider_id     = :provider_id,
	cost_status_id  = :cost_status_id,
	cost_type_id    = :cost_type_id,
	cost_center_id  = :cost_center_id,
	template_id     = :template_id,
	effective_date  = :invoice_date,
	start_block     = ( select max(start_block)
			    from im_start_months
			    where start_block < :invoice_date),
	payment_days    = :payment_days,
	vat	     = :vat,
	tax	     = :tax,
	note	    = :note,
	variable_cost_p = 't',
	amount	  = null,
	currency	= null
where
	cost_id = :invoice_id
;

-- Delete an invoice
-- The delete operation depends on the particular 
-- object type of the invoice. It's usually "im_invoice",
-- but there can be subtypes in the future. Executing
-- the following is save:
--
select ${otype}__delete(:cost_id);


-- Updating Invoice Items. These are the individual
-- lines of the invoice. We usually just delete all
-- items for an invoice and the insert them again.
--
-- set item_id [db_nextval "im_invoice_items_seq"]
INSERT INTO im_invoice_items (
	item_id, item_name,
	project_id, invoice_id,
	item_units, item_uom_id,
	price_per_unit, currency,
	sort_order, item_type_id,
	item_status_id, description
) VALUES (
	:item_id, :name,
	:project_id, :invoice_id,
	:units, :uom_id,
	:rate, :currency,
	:sort_order, :type_id,
	null, ''
);


-- Calculate the invoice total from the invoice items
update im_costs set 
	amount = (
		select sum(price_per_unit * item_units)
		from im_invoice_items
		where invoice_id = :invoice_id
		group by invoice_id
	),
	currency = :currency
where cost_id = :invoice_id;


-- Determine the number of different currencies
-- defined in the invoice_items.
-- We get a multicurrency issue if these are different...
select distinct
	currency as invoice_currency
from    im_invoice_items i
where   i.invoice_id = :invoice_id";


-- Create a new Invoice
select im_invoice__new (
	:invoice_id,		-- invoice_id
	'im_invoice',		-- object_type
	now(),			-- creation_date
	:user_id,		-- creation_user
	'[ad_conn peeraddr]',   -- creation_ip
	null,			-- context_id
	:invoice_nr,		-- invoice_nr
	:company_id,		-- company_id
	:provider_id,		-- provider_id
	null,			-- company_contact_id
	:invoice_date,		-- invoice_date
	'EUR',			-- currency
	:template_id,		-- invoice_template_id
	:cost_status_id,	-- invoice_status_id
	:cost_type_id,		-- invoice_type_id
	:payment_method_id,     -- payment_method_id
	:payment_days,		-- payment_days
	0,			-- amount
	:vat,			-- vat
	:tax,			-- tax
	:note			-- note
);


-- Create a new relationship between a Project and an Invoice.
-- The relationship can be N:M, so we're using acs_rels.
--
select acs_rel__new (
	null,		-- rel_id
	'relationship',	-- rel_type
	:project_id,	-- object_id_one
	:invoice_id,	-- object_id_two
	null,		-- context_id
	null,		-- creation_user
	null		-- creation_ip
);



-- Delete all relationships of a invoice with a project (:object_id)
DECLARE
	row record;
BEGIN
	for row in
		select distinct r.rel_id
		from    acs_rels r
		where   r.object_id_one = :object_id
			and r.object_id_two = :invoice_id
	loop
		PERFORM acs_rel__delete(row.rel_id);
	end loop;
	return 0;
END;



-- Select all invoices associated to a project.
-- This rather complex query is necessary if you want to know 
-- how much has been spent on a project AND its subprojects.
--
select	i.*
from	im_invoices i
where	i.invoice_id in (
		select distinct cost_id
		from im_costs
		where project_id in (
			select  children.project_id
			from    im_projects parent,
				im_projects children
			where   children.tree_sortkey
					between parent.tree_sortkey
					and tree_right(parent.tree_sortkey)
				and parent.project_id = :project_id
		)
	    UNION
		select distinct object_id_two as cost_id
		from acs_rels
		where object_id_one in (
			select  children.project_id
			from    im_projects parent,
				im_projects children
			where   children.tree_sortkey
					between parent.tree_sortkey
					and tree_right(parent.tree_sortkey)
				and parent.project_id = :project_id
		)
);


-- ---------------------------------------------------------
-- Invoices
--
-- An invoice basically is a container of im_invoice_lines.
-- The problem is that invoices can be vastly different 
-- from business to business, and that invoices may emerge
-- as a result of negotiations between the comapany and the
-- client, so that basically nothing is really fixed or
-- consistent with the project data.
--
-- So the idea of this module is to _generate_ the invoices
-- automatically and consistently from the project data,
-- but to allow invoices to be edit manually in every respect.
--
-- Options to create invoices include:
--	- exactly one invoice for each project
--	- include multipe projects in one invoice
--	- multiple invoices per project (partial invoices)
--	- invoices without project
--
-- As a side effect of creating an invoice, the status of
-- the associated projects may be set to "invoiced", as
-- well as the status of the projects tasks of those 
-- projects (if the project-tasks module is installed).

create table im_invoices (
	invoice_id		integer
				constraint im_invoices_pk
				primary key
				constraint im_invoices_id_fk
				references im_costs,
	company_contact_id	integer 
				constraint im_invoices_contact
				references users,
	invoice_nr		varchar(40)
				constraint im_invoices_nr_un unique,
	payment_method_id	integer
				constraint im_invoices_payment
				references im_categories,
	-- the PO of a provider bill or the quote of an invoice
	reference_document_id	integer
				constraint im_invoices_reference_doc
				references im_invoices,
	invoice_office_id	integer
				constraint im_invoices_office_fk
				references im_offices
);

-----------------------------------------------------------
-- Invoice Items
--
-- - Invoice items reflect the very fuzzy structure of invoices,
--   that may contain basically everything that fits in one line
--   and has a price.
-- - Invoice items can created manually or generated from
--   "invoicable items" such as im_trans_tasks, timesheet information
--    or similar.
-- All fields (number of units, price, description) need to be 
-- human editable because invoicing is so messy...

create sequence im_invoice_items_seq start 1;
create table im_invoice_items (
	item_id			integer
				constraint im_invoices_items_pk
				primary key,
	item_name		varchar(200),
				-- not being used yet (V3.0.0).
				-- reserved for adding a reference nr for items
				-- from a catalog or similar
	item_nr			varchar(200),
				-- project_id if != null is used to access project details
				-- for invoice generation, such as the company PO# etc.
	project_id		integer
				constraint im_invoices_items_project
				references im_projects,
	invoice_id		integer not null 
				constraint im_invoices_items_invoice
				references im_invoices,
	item_units		numeric(12,1),
	item_uom_id		integer not null 
				constraint im_invoices_items_uom
				references im_categories,
	price_per_unit 		numeric(12,3),
	currency		char(3)
				constraint im_invoices_items_currency
				references currency_codes(ISO),
	sort_order		integer,
	item_type_id		integer
				constraint im_invoices_items_item_type
				references im_categories,
	item_status_id		integer
				constraint im_invoices_items_item_status
				references im_categories,
				-- include in VAT calculation?
	apply_vat_p		char(1) default('t')
				constraint im_invoices_apply_vat_p
				check (apply_vat_p in ('t','f')),
	description		varchar(4000),
		-- Make sure we can''t create duplicate entries per invoice
		constraint im_invoice_items_un
		unique (item_name, invoice_id, project_id, item_uom_id)
);
