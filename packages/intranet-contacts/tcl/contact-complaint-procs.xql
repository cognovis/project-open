<? xml version="1.0" ?>

<queryset>

<fullquery name="contact::complaint::new.insert_complaint">
    <querytext>
	insert into
  	   contact_complaint_track 
	   (complaint_id,customer_id,turnover,percent,supplier_id,paid,complaint_object_id,state,employee_id,refund_amount)
	   values
           (:complaint_id,:customer_id,:turnover,:percent,:supplier_id,:paid,:complaint_object_id,:state,:employee_id,:refund_amount)
    </querytext>
</fullquery>

<fullquery name="contact::complaint::new.get_item_id">
    <querytext>
	select
		item_id
	from 
		cr_revisions
	where
		revision_id = :complaint_id
    </querytext>
</fullquery>

<fullquery name="contact::complaint::check_name.check_name">
    <querytext>
	select
		1
	from 
		cr_items
	where
		name = :name
		and parent_id = :parent_id
    </querytext>
</fullquery>

</queryset>

