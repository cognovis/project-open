<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.2</version></rdbms>

<fullquery name="add_organization_rel">
    <querytext>
		    select acs_rel__new (
					 null,
					 'organization_rel',
					 :group_id,
					 :party_id,
					 :group_id,
					 :user_id,
					 :ip_addr
					 )
    </querytext>
</fullquery>

</queryset>
