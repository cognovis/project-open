------------------------------------------------------------
-- Payments
------------------------------------------------------------

-- Get everything about an individual payment
select
	p.*,
	ci.cost_name,
	ci.customer_id,
	c.company_name,
	pro.company_name as provider_name,
	to_char(p.start_block,'Month DD, YYYY') as start_block,
	im_category_from_id(p.payment_type_id) as payment_type
from
	im_companies c,
	im_companies pro,
	im_payments p,
	im_costs ci
where
	p.cost_id = ci.cost_id
	and ci.customer_id = c.company_id
	and ci.provider_id = pro.company_id
	and p.payment_id = :payment_id;


-- Get the list of all payments
select
	p.*,
	to_char(p.received_date,'YYYY-MM-DD') as received_date,
	p.amount as payment_amount,
	p.currency as payment_currency,
	ci.customer_id,
	ci.amount as cost_amount,
	ci.currency as cost_currency,
	ci.cost_name,
	acs_object.name(ci.customer_id) as company_name,
	im_category_from_id(p.payment_type_id) as payment_type,
	im_category_from_id(p.payment_status_id) as payment_status
from
	im_payments p,
	im_costs ci
where
	p.cost_id = ci.cost_id;


-- Update Payments
update
	im_payments
set
	cost_id =		:cost_id,
	amount =		:amount,
	currency =	 	:currency,
	received_date =	 	:received_date,
	payment_type_id =       :payment_type_id,
	note =		 	:note,
	last_modified =	 	:last_modified_date,
	last_modifying_user =   :user_id,
	modified_ip_address =   :modified_ip_address
where
	payment_id = :payment_id"


-- Insert a new payment record
insert into im_payments (
	payment_id,
	cost_id,
	company_id,
	provider_id,
	amount,
	currency,
	received_date,
	payment_type_id,
	note,
	last_modified,
	last_modifying_user,
	modified_ip_address
) values (
	:payment_id,
	:cost_id,
	:company_id,
	:provider_id,
	:amount,
	:currency,
	:received_date,
	:payment_type_id,
	:note,
	(select sysdate from dual),
	:user_id,
	'[ns_conn peeraddr]'
);

-- Don't forget to update the "paid_amount" of the im_cost
-- item after you add a payment. Please use the function:
-- im_cost_update_payments $cost_id.


-- Deleting a payment
delete from im_payments where payment_id = :pid


------------------------------------------------------
-- Payments
--
-- Tracks the money coming into a cost item over time
--

create sequence im_payments_id_seq start 10000;
create table im_payments (
	payment_id		integer not null 
				constraint im_payments_pk
				primary key,
	cost_id			integer
				constraint im_payments_cost
				references im_costs,
				-- who pays?
	company_id		integer not null
				constraint im_payments_company
				references im_companies,
				-- who gets paid?
	provider_id		integer not null
				constraint im_payments_provider
				references im_companies,
	received_date		timestamptz,
	start_block		timestamptz 
				constraint im_payments_start_block
				references im_start_months,
	payment_type_id		integer
				constraint im_payments_type
				references im_categories,
	payment_status_id	integer
				constraint im_payments_status
				references im_categories,
	amount			numeric(12,2),
	currency		char(3) 
				constraint im_payments_currency
				references currency_codes(ISO),
	note			varchar(4000),
	last_modified   	timestamptz not null,
 	last_modifying_user	integer not null 
				constraint im_payments_mod_user
				references users,
	modified_ip_address	varchar(20) not null,
		-- Make sure we don't get duplicated entries for 
		-- whatever reason
		constraint im_payments_un
		unique (company_id, cost_id, provider_id, received_date, 
			start_block, payment_type_id, currency)
);
