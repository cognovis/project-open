<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="create_q_and_a">      
      <querytext>
        select faq__new_q_and_a (
             	:entry_id,
             	:faq_id,
             	:question,
             	:answer,
 							:sort_key,
							'faq_q_and_a',
							now(),
             	:user_id,
             	:creation_ip,
							:faq_id
            );
      </querytext>
</fullquery>

 
</queryset>
