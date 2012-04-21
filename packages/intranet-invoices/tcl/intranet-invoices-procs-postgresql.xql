<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="im_invoices_object_list_component.object_list">
    <querytext>
        select distinct
	   	o.object_id,
		o.object_type,
		acs_object__name(o.object_id) as object_name,
		u.url
	from
	        acs_objects o,
	        acs_rels r,
		im_biz_object_urls u
	where
	        r.object_id_one = o.object_id
	        and r.object_id_two = :invoice_id
		and u.object_type = o.object_type
		and u.url_type = 'view'
                and r.rel_type != 'im_invoice_invoice_rel'
   </querytext>
</fullquery>
<fullquery name="im_invoice_copy_new.create_invoice">
        <querytext>

  select im_invoice__new (
                :new_invoice_id,		-- invoice_id
		'im_invoice',		-- object_type
		now(),			-- creation_date 
                :user_id,		-- creation_user
                '[ad_conn peeraddr]',	-- creation_ip
		null,			-- context_id
                :invoice_nr,		-- invoice_nr
                :customer_id,		-- company_id
                :provider_id,		-- provider_id
		null,			-- company_contact_id
                now(),		-- invoice_date
		'EUR',			-- currency
                :template_id,		-- invoice_template_id
                :cost_status_id,	-- invoice_status_id
                :target_cost_type_id,		-- invoice_type_id
                :payment_method_id,	-- payment_method_id
                :payment_days,		-- payment_days
                0,			-- amount
                :vat,			-- vat
                :tax,			-- tax
                :note			-- note
            )
        </querytext>
</fullquery>
<fullquery name="im_invoice_copy_new.create_rel">
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
<fullquery name="im_invoice_copy_new.create_invoice_rel">
    <querytext>

      select acs_rel__new (
             null,             -- rel_id
             'im_invoice_invoice_rel',   -- rel_type
             :source_id,      -- object_id_one
             :invoice_id,      -- object_id_two
             null,             -- context_id
             null,             -- creation_user
             null             -- creation_ip
      )

    </querytext>
</fullquery>

</queryset>
