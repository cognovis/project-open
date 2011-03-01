<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="create_faq">      
      <querytext>
	  select faq__new_faq (:faq_id, :faq_name,:separate_p,'faq', now(), :user_id,:creation_ip,:package_id);
      </querytext>
</fullquery>

 
</queryset>
