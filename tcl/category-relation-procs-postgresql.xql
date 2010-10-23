<?xml version="1.0"?>
<queryset>

<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="category::relation::add_meta_category.add_meta_relation">
    <querytext>
	 select acs_rel__new ( null, 'meta_category_rel', :category_id_one, :category_id_two, null, null, null )
    </querytext>
</fullquery>

<fullquery name="category::relation::add_meta_category.add_user_meta_relation">
    <querytext>
	 select acs_rel__new ( null, 'user_meta_category_rel', :meta_category_id, :user_id, null, null, null )
    </querytext>
</fullquery>

</queryset>
