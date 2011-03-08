<?xml version="1.0"?> 
 
<queryset> 
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms> 
 
<fullquery name="create_faq">       
      <querytext> 
        begin 
          :1 := faq.new_faq ( 
                    faq_id => :faq_id, 
                    faq_name => :faq_name, 
                    separate_p => :separate_p, 
                    creation_user => :user_id, 
                    creation_ip => :creation_ip, 
                    context_id => :package_id 
                ); 
        end; 
      </querytext> 
</fullquery> 
 
  
</queryset> 
 
