-- /package/intranet-payments/sql/oracle/intranet-payments-create.sql
--
-- Payments module for Project/Open
--
-- (c) 2003 Frank Bergmann (frank.bergmann@project-open.com)
--
-- Defines:
--	im_payments			Payments
--	im_payments_audit		History of payment changes

------------------------------------------------------
-- Payments
--
-- Tracks the money coming into a cost item over time
--

create sequence im_payments_id_seq start with 10000;
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
	received_date		date,
	start_block		date 
				constraint im_payments_start_block
				references im_start_months,
	payment_type_id		integer
				constraint im_payments_type
				references im_categories,
	payment_status_id	integer
				constraint im_payments_status
				references im_categories,
	amount			number(12,2),
	currency		char(3) 
				constraint im_payments_currency
				references currency_codes(ISO),
	note			varchar(4000),
	last_modified   	date not null,
 	last_modifying_user	not null 
				constraint im_payments_mod_user
				references users,
	modified_ip_address	varchar(20) not null,
		-- Make sure we don't get duplicated entries for 
		-- whatever reason
		constraint im_payments_un
		unique (company_id, cost_id, provider_id, received_date, 
			start_block, payment_type_id, currency)
);

create index im_proj_payments_cost_id_idx on im_payments(cost_id);



------------------------------------------------------
-- Permissions and Privileges
--

begin
    acs_privilege.create_privilege('view_payments','View Payments','View Payments');
    acs_privilege.add_child('admin', 'view_payments');

    acs_privilege.create_privilege('add_payments','View Payments','View Payments');
    acs_privilege.add_child('admin', 'add_payments');
end;
/
show errors;



BEGIN
    im_priv_create('view_payments','Accounting');
    im_priv_create('view_payments','P/O Admins');
    im_priv_create('view_payments','Senior Managers');
END;
/
show errors;

BEGIN
    im_priv_create('add_payments','Accounting');
    im_priv_create('add_payments','P/O Admins');
    im_priv_create('add_payments','Senior Managers');
END;
/
show errors;


------------------------------------------------------
-- Audit all payment transactions
--

create table im_payments_audit (
	payment_id		integer,
	cost_id			integer,
	company_id		integer,
	provider_id		integer,
	received_date		date,
	start_block		date,
	payment_type_id		integer,
	payment_status_id	integer,
	amount			number(12,2),
	currency		char(3),
	note			varchar(4000),
	last_modified   	date not null,
 	last_modifying_user	integer,
	modified_ip_address	varchar(20) not null
);
create index im_proj_payments_aud_id_idx on im_payments_audit(payment_id);

create or replace trigger im_payments_audit_tr
	before update or delete on im_payments
	for each row
	begin
		insert into im_payments_audit (
			payment_id,
			cost_id,
			company_id,
			provider_id,
			received_date,
			start_block,
			payment_type_id,
			payment_status_id,
			amount,
			currency,
			note,
			last_modified,
			last_modifying_user,
			modified_ip_address
		) values (
			:old.payment_id,
			:old.cost_id,
			:old.company_id,
			:old.provider_id,
			:old.received_date,
			:old.start_block,
			:old.payment_type_id,
			:old.payment_status_id,
			:old.amount,
			:old.currency,
			:old.note,
			:old.last_modified,
			:old.last_modifying_user,
			:old.modified_ip_address
		);
end im_payments_audit_tr;
/
show errors


create or replace view im_payment_type as 
select category_id as payment_type_id, category as payment_type
from im_categories 
where category_type = 'Intranet Payment Type';

create or replace view im_invoice_payment_method as 
select 
	category_id as payment_method_id, 
	category as payment_method, 
	category_description as payment_description
from im_categories 
where category_type = 'Intranet Invoice Payment Method';


------------------------------------------------------
-- Add a "New Payments" item into the Costs submenu
------------------------------------------------------

BEGIN
    im_component_plugin.del_module(module_name => 'intranet-payments');
    im_menu.del_module(module_name => 'intranet-payments');
END;
/
commit;

declare
        -- Menu IDs
        v_menu                  integer;
	v_finance_menu		integer;
	v_invoices_new_menu	integer;
        -- Groups
        v_employees             integer;
        v_accounting            integer;
        v_senman                integer;
        v_companies             integer;
        v_freelancers           integer;
        v_proman                integer;
        v_admins                integer;
begin
    select group_id into v_admins from groups where group_name = 'P/O Admins';
    select group_id into v_senman from groups where group_name = 'Senior Managers';
    select group_id into v_accounting from groups where group_name = 'Accounting';
    select group_id into v_companies from groups where group_name = 'Customers';
    select group_id into v_freelancers from groups where group_name = 'Freelancers';

    select menu_id
    into v_finance_menu
    from im_menus
    where label='finance';

    delete from im_menus where package_name='intranet-payments';

    v_menu := im_menu.new (
	package_name =>	'intranet-payments',
	label =>	'payments_list',
	name =>		'Payments',
	url =>		'/intranet-payments/index',
	sort_order =>	20,
	parent_menu_id => v_finance_menu
    );

    acs_permission.grant_permission(v_menu, v_admins, 'read');
    acs_permission.grant_permission(v_menu, v_senman, 'read');
    acs_permission.grant_permission(v_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_menu, v_companies, 'read');
    acs_permission.grant_permission(v_menu, v_freelancers, 'read');


    -- Add a line to the "Finance/New" page
--    select menu_id
--    into v_invoices_new_menu
--    from im_menus
--    where label='finance_new';

    v_menu := im_menu.new (
	package_name =>	'intranet-payments',
	label =>	'payments_new',
	name =>		'New Payment',
	url =>		'/intranet-payments/new?',
	sort_order =>	90,
	parent_menu_id => v_menu
    );

    acs_permission.grant_permission(v_menu, v_admins, 'read');
    acs_permission.grant_permission(v_menu, v_senman, 'read');
    acs_permission.grant_permission(v_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_menu, v_companies, 'read');
    acs_permission.grant_permission(v_menu, v_freelancers, 'read');
end;
/
commit;
	

------------------------------------------------------
-- Invoice Views
--
-- 30 invoice list
-- 31 invoice_new
insert into im_views (view_id, view_name, visible_for) 
values (32, 'payment_list', 'view_finance');

-- Payment List Page
--
delete from im_view_columns where column_id > 3200 and column_id < 3299;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (3201,32,NULL,'Payment #',
'"<A HREF=/intranet-payments/view?payment_id=$payment_id>$payment_id</A>"','','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (3203,32,NULL,'Invoice',
'"<A HREF=/intranet-invoices/view?invoice_id=$cost_id>$cost_name</A>"','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (3205,32,NULL,'Client',
'"<A HREF=/intranet/companies/view?company_id=$company_id>$company_name</A>"','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (3207,32,NULL,'Received',
'$received_date','','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (3209,32,NULL,'Invoice Amount',
'$cost_amount','','',9,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (3211,32,NULL,'Amount Paid',
'$payment_amount $currency','','',11,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (3213,32,NULL,'Status',
'$payment_status_id','','',13,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (3290,32,NULL,'Del',
'[if {1} {set ttt "<input type=checkbox name=del_payment value=$payment_id>"}]','','',99,'');

--
commit;


-- Payment Type
delete from im_categories where category_id >= 1000 and category_id < 1100;
INSERT INTO im_categories VALUES (1000,'Bank Transfer','','Intranet Payment Type',
'category','t','f');
INSERT INTO im_categories VALUES (1002,'Cheque','','Intranet Payment Type',
'category','t','f');
commit;
-- reserved until 1099
