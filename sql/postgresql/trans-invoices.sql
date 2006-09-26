------------------------------------------------------------
-- Translation Invoices
------------------------------------------------------------


-- Get everything from a Trans Invoice
-- => Same as Invoice

-- Create a new Trans Invoice
 select im_trans_invoice__new (
		:invoice_id,
		'im_trans_invoice',
		now(),
		:user_id,
		'[ad_conn peeraddr]',
		null,
		:invoice_nr,
		:customer_id,
		:provider_id,
		null,
		:invoice_date,
		'EUR',
		:template_id,
		:cost_status_id,
		:cost_type_id,
		:payment_method_id,
		:payment_days,
		'0',
		:vat,
		:tax,
		null
);

-- => Please see Invoices for more updates


-- Get the object and (optionally) it's Trados Matrix
select
	m.*,
	acs_object__name(o.object_id) as object_name
from
	acs_objects o
	LEFT JOIN
		im_trans_trados_matrix m USING (object_id)
where
	o.object_id = :object_id
;


update im_trans_trados_matrix set
	match_x = :match_x,
	match_rep = :match_rep,
	match100 = :match100,
	match95 = :match95,
	match85 = :match85,
	match75 = :match75,
	match50 = :match50,
	match0 = :match0
where
	object_id = :object_id;


---------------------------------------------------------
-- Trados Matrix by object (normally by company)
create table im_trans_trados_matrix (
	object_id	integer
			constraint im_trans_matrix_cid_fk
			references acs_objects
			constraint im_trans_matrix_pk
			primary key,
	match_x		numeric(12,4),
	match_rep	numeric(12,4),
	match100	numeric(12,4),
	match95	  	numeric(12,4),
	match85	  	numeric(12,4),
	match75		numeric(12,4),
	match50		numeric(12,4),
	match0	   	numeric(12,4)
);


---------------------------------------------------------
-- Translation Invoices
--
-- We have made a "Translation Invoice" a separate object
-- mainly because it requires a different treatment when
-- it gets deleted, because of its interaction with
-- im_trans_tasks and im_projects, that are affected
-- (set back to the status "delivered") when a trans-invoice
-- is deleted.


create table im_trans_invoices (
	invoice_id		integer
				constraint im_trans_invoices_pk
				primary key
				constraint im_trans_invoices_fk
				references im_invoices
);

