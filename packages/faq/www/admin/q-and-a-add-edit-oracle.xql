<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="create_q_and_a">      
      <querytext>
        begin 
            :1 := faq.new_q_and_a ( 
                entry_id => :entry_id, 
                context_id => :faq_id, 
                faq_id=> :faq_id, 
                question => :question, 
                answer => :answer, 
                sort_key => :sort_key, 
                creation_user => :user_id, 
                creation_ip => :creation_ip 
            ); 
        end; 
      </querytext>
</fullquery>
 
</queryset>
