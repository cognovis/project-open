<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>
	<fullquery name="create_expense">
		<querytext>
		select im_expense__new (
			:expense_id,			-- expense_id
			'im_expense',			-- object_type
			now(),				-- creation_date 
			:user_id_from_search,		-- creation_user
			'[ad_conn peeraddr]',		-- creation_ip
			null,				-- context_id
			:expense_name,			-- expense_name
			:project_id,			-- project_id
			:expense_date,			-- expense_date now()
			:currency,			-- expense_currency default ''EUR''
			null,				-- expense_template_id default null
			:cost_status,			-- expense_status_id default 3802
			:cost_type_id,			-- expense_type_id default 3720
			30,				-- payment_days default 30
			:amount,			-- amount
			:vat,				-- vat default 0
			0,				-- tax default 0
			:note,				-- note
			:external_company_name,		-- hotel name, taxi, ...
			:external_company_vat_number,	-- vat number
			:receipt_reference,		-- receip reference
			:expense_type_id,		-- expense type default null
			:billable_p,			-- is billable to client 
			:reimbursable,			-- % reibursable from amount value
			:expense_payment_type_id, 	-- credit card used to pay, ...
			:customer_id,			-- customer
			:provider_id			-- provider
		)
		</querytext>
	</fullquery>

	<fullquery name="update_expense">
		<querytext>
		update im_expenses 
		set 
			external_company_name		= :external_company_name,
			external_company_vat_number	= :external_company_vat_number,
			receipt_reference		= :receipt_reference,
			billable_p			= :billable_p,
			reimbursable			= :reimbursable,
			expense_payment_type_id		= :expense_payment_type_id,
			expense_type_id			= :expense_type_id
		where
			expense_id = :expense_id
		</querytext>
	</fullquery>

	<fullquery name="update_cost">
		<querytext>
		update im_costs
		set
			project_id	= :project_id,
			cost_name	= :expense_name,
			customer_id	= :customer_id,
			cost_nr		= :expense_id,
			cost_type_id	= :cost_type_id,
			provider_id	= :provider_id,
			cost_center_id	= :cost_center_id,
			template_id	= :template_id,
			effective_date	= to_timestamp(:expense_date, 'YYYY-MM-DD'),
			payment_days	= :payment_days,
			vat		= :vat,
			tax		= :tax,
			variable_cost_p = 't',
			amount		= :amount,
			currency	= :currency,
			note		= :note
		where
			cost_id = :expense_id
		</querytext>
	</fullquery>

	<fullquery name="__create_rel">
		<querytext>
		select acs_rel__new (
			null,			-- rel_id
			'relationship',		-- rel_type
			:project_id,		-- object_id_one
			:bundle_id,		-- object_id_two
			null,			-- context_id
			null,			-- creation_user
			null			-- creation_ip
		)
		</querytext>
	</fullquery>
</queryset>
