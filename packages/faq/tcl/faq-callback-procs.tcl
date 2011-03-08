
ad_proc -callback application-track::getApplicationName -impl faqs {} { 
        callback implementation 
    } {
        return "faqs"
    }    
    
    ad_proc -callback application-track::getGeneralInfo -impl faqs {} { 
        callback implementation 
    } {
	db_1row my_query {
    		select count(f.faq_id) as result
			from faqs f, acs_objects o, dotlrn_communities com, acs_objects ac
		    	where o.object_id=f.faq_id
			and com.community_id=:comm_id					
			and o.context_id = ac.object_id
			and ac.context_id = com.package_id	
	}
	
	return "$result"
    }
    
    ad_proc -callback application-track::getSpecificInfo -impl faqs {} { 
        callback implementation 
    } {
   	
	upvar $query_name my_query
	upvar $elements_name my_elements

	set my_query {
		select f.faq_name as name,f1.question as question,f1.answer as answer,u.username as creator, o.creation_date as creation_date
			from faqs f, acs_objects o, dotlrn_communities com,faq_q_and_as f1, acs_objects ac,users u
		    	where o.object_id=f.faq_id
			and com.community_id=:class_instance_id		
			and f.faq_id = f1.faq_id
			and o.context_id = ac.object_id
			and ac.context_id = com.package_id
			and o.creation_user = u.user_id
 }
		
	set my_elements {
    		name {
	            label "Name"
	            display_col name	                        
	 	    html {align center}
	 	               
	        }
	        questions {
	            label "Questions"
	            display_col question 	      	              
	 	    html {align center} 	 	                
	        }
	        answers {
	            label "Answers"
	            display_col answer 	      	              
	 	    html {align center}	 	                
	        }
	          creator {
	            label "Creator"
	            display_col creator 	      	              
	 	    html {align center}	 	                
	        }
	          creation_date {
	            label "Creation_date"
	            display_col creation_date 	      	              
	 	    html {align center}	 	                
	        }
        
	}

        return "OK"
    }