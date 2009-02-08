<?xml version="1.0"?>
<queryset>

<fullquery name="contact::extend::delete.extend_delete">
    <querytext>
        delete from 
		contact_extend_options 
	where 
		extend_id = :extend_id
    </querytext>
</fullquery>

<fullquery name="contact::extend::new.new_extend_option">
    <querytext>
	insert into contact_extend_options (extend_id,var_name,pretty_name,subquery,description,aggregated_p)
        values (:extend_id,:var_name,:pretty_name,:subquery,:description,:aggregated_p)
    </querytext>
</fullquery>

<fullquery name="contact::extend::update.update_extend_option">
    <querytext>
      	update contact_extend_options
        set var_name = :var_name, 
	    pretty_name = :pretty_name, 
            subquery = :subquery, 
            description = :description, 
            aggregated_p = :aggregated_p
        where extend_id = :extend_id
    </querytext>
</fullquery>

<fullquery name="contact::extend::var_name_check.check_name">
    <querytext>
	select 
		1
	from 
		contact_extend_options
	where
		var_name = :var_name
    </querytext>
</fullquery>

<fullquery name="contact::extend::get_options.get_options">
    <querytext>
	select 
		pretty_name, 
		extend_id
	from 
		contact_extend_options
		$extra_query
		and aggregated_p = :aggregated_p
    </querytext>
</fullquery>

<fullquery name="contact::extend::option_info.get_options">
    <querytext>
	select 
		var_name,
		pretty_name, 
		subquery,
		description,
		aggregated_p
	from 
		contact_extend_options
	where
		extend_id = :extend_id
    </querytext>
</fullquery>

</queryset>

