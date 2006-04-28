<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="create_expense">
        <querytext>

  select im_expense__new (
                :expense_id,			-- expense_id
		'im_expense',			-- object_type
		now(),				-- creation_date 
                :user_id,			-- creation_user
                '[ad_conn peeraddr]',		-- creation_ip
		null,				-- context_id
		'NEW EXPENSE',         		-- expense_name
        	:project_id,            	-- project_id
        	$expense_date_sql,          	-- expense_date now()
        	'EUR',		        	-- expense_currency default ''EUR''
        	null,		        	-- expense_template_id default null
        	:cost_status,                    	-- expense_status_id default 3802
        	:cost_type_id,	 	        	-- expense_type_id default 3720
        	30,		        	-- payment_days default 30
		:amount,        		-- amount
		0,	                	-- vat default 0
		0,		        	-- tax default 0
		'',	                	-- note
		:vat_included,			-- vat included
		:external_company_name,		-- hotel name, taxi, ...
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
<fullquery name="__create_rel">
    <querytext>

      select acs_rel__new (
             null,             -- rel_id
             'relationship',   -- rel_type
             :project_id,      -- object_id_one
             :invoice_id,      -- object_id_two
             null,             -- context_id
             null,             -- creation_user
             null             -- creation_ip
      )

    </querytext>
</fullquery>
</queryset>
