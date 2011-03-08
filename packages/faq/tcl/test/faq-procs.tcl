ad_library {
    Automated tests.
    @author Mounir Lallali
    @creation-date 14 June 2005
}

aa_register_case -cats {web smoke} -libraries tclwebtest tclwebtest_new_faq {

	A simple test case to faq package :  Test Create Faq.

} {
	aa_run_with_teardown -test_code {
	    
	    tclwebtest::cookies clear
	    # Login user
	    array set user_info [twt::user::create -admin]
	    twt::user::login $user_info(email) $user_info(password)

	    # Create a new Faq
	    set faq_name [ad_generate_random_string]
	    set response [faq::twt::new $faq_name] 
	    aa_display_result -response $response -explanation {Webtest for the creation of a new Faq}
	    
	    twt::user::logout
	}            	

}

aa_register_case -cats {web smoke} -libraries tclwebtest tclwebtest_delete_faq {

    A simple test case to faq package :  Test Delete Faq.

} {
	aa_run_with_teardown -test_code {
		
	    tclwebtest::cookies clear
	    # Login user
	    array set user_info [twt::user::create -admin]
	    twt::user::login $user_info(email) $user_info(password)

	    # Create a new Faq
	    set faq_name [ad_generate_random_string]
	    faq::twt::new $faq_name
	    
	    # Delete a Faq
	    set response [faq::twt::delete $faq_name]
	    aa_display_result -response $response -explanation {Webtest for deleting a Faq}
	    
	    twt::user::logout
        }
}

aa_register_case -cats {web smoke} -libraries tclwebtest tclwebtest_edit_one_faq {

    A simple test case to faq package :  Test edit Faq - Fisrt Scenario. 

} {
	aa_run_with_teardown -test_code {
	    
	    tclwebtest::cookies clear
	    # Login user
	    array set user_info [twt::user::create -admin]
	    twt::user::login $user_info(email) $user_info(password)

	    # Create a new Faq
	    set faq_name [ad_generate_random_string]
	    set new_faq_name [ad_generate_random_string]
	    faq::twt::new $faq_name 
	    
	    # Rename a Faq by editing
	    set response [faq::twt::edit_one $faq_name $new_faq_name]
	    aa_display_result -response $response -explanation {Webtest for editing a Faq - First Scenario}
	    twt::user::logout
        }          	
}	

aa_register_case -cats {web smoke} -libraries tclwebtest tclwebtest_edit_two_faq {

    A simple test case to faq package :  Test edit Faq - Second Scenario. 

} {
	aa_run_with_teardown -test_code {

	    tclwebtest::cookies clear
	    # Login user
	    array set user_info [twt::user::create -admin]
	    twt::user::login $user_info(email) $user_info(password)

	    # Create a new Faq
	    set faq_name [ad_generate_random_string]
	    faq::twt::new $faq_name

	    # Rename a Faq by editing
	    set new_faq_name [ad_generate_random_string]
	    set response [faq::twt::edit_two $faq_name $new_faq_name]
	    aa_display_result -response $response -explanation {Webtest for editing a Faq - Second Scenario}
	    
	    twt::user::logout
	}            	
}

aa_register_case -cats {web smoke} -libraries tclwebtest tclwebtest_disable_faq {

    A simple test case to faq package :  Test Disable Faq. 

} {
	aa_run_with_teardown -test_code {
	
	    tclwebtest::cookies clear
	    # Login user
	    array set user_info [twt::user::create -admin]
	    twt::user::login $user_info(email) $user_info(password)
 
	    # Create a new Faq
	    set faq_name [ad_generate_random_string]
	    faq::twt::new $faq_name

	    # Disable a Faq
	    set option "disable"		
	    set response [faq::twt::disable_enable $faq_name $option]
	    aa_display_result -response $response -explanation {Webtest for disabling a Faq}
	    
	    twt::user::logout
	}            	
}

aa_register_case -cats {web smoke} -libraries tclwebtest tclwebtest_enable_faq {
    
    A simple test case to faq package :  Test Enable Faq. 

} {
	aa_run_with_teardown -test_code {
		
	    tclwebtest::cookies clear
	    # Login user
	    array set user_info [twt::user::create -admin]
	    twt::user::login $user_info(email) $user_info(password)

	    # Create a new Faq
	    set faq_name [ad_generate_random_string]
	    faq::twt::new $faq_name

	    #  Disable a Faq
	    set option "disable"		
	    faq::twt::disable_enable $faq_name $option
	    
	    #  Enable a Faq
	    set option "enable"
	    set response [faq::twt::disable_enable $faq_name $option]
	    aa_display_result -response $response -explanation {Webtest for enabling a Faq}
	    
	    twt::user::logout
	}           	
}

aa_register_case -cats {web smoke} -libraries tclwebtest tclwebtest_new_Q_A_faq {

	A simple test case to faq package :  Create a new Q&A. 

} {
	aa_run_with_teardown -test_code {  

	    tclwebtest::cookies clear
	    # Login user
	    array set user_info [twt::user::create -admin]
	    twt::user::login $user_info(email) $user_info(password)
	    
            # Create a new Faq
	    set faq_name [ad_generate_random_string]
	    faq::twt::new $faq_name
	    
	    # Create a new Question_Answer
	    set question [ad_generate_random_string]
            set answer [ad_generate_random_string]
	    set response [faq::twt::new_Q_A $faq_name $question $answer]
	    aa_display_result -response $response -explanation {Webtest for creating a New Question in a Faq}
	    
	    twt::user::logout
	}           	
}

aa_register_case -cats {web smoke} -libraries tclwebtest tclwebtest_delete_Q_A_faq {

    A simple test case to faq package :  Delete a Q&A. 

} {
	aa_run_with_teardown -test_code {  
	
	    tclwebtest::cookies clear
            # Login user
	    array set user_info [twt::user::create -admin]
            twt::user::login $user_info(email) $user_info(password)

	     # Create a new Faq
	    set faq_name [ad_generate_random_string]
	    faq::twt::new $faq_name

	    # Create a new Question_Answer
            set question [ad_generate_random_string]
            set answer [ad_generate_random_string]
	    faq::twt::new_Q_A $faq_name $question $answer
	    
	    # Delete a Question_Answer
	    set response [faq::twt::delete_Q_A $faq_name $answer] 
	    aa_display_result -response $response -explanation {Webtest for deleting a Question in a Faq}
	    
	    twt::user::logout
	}            	
}

aa_register_case -cats {web smoke} -libraries tclwebtest tclwebtest_edit_Q_A_faq {

    A simple test case to faq package :  Edit  a Q&A. 

} {
	aa_run_with_teardown -test_code {  
	
           tclwebtest::cookies clear
           # Login user
	   array set user_info [twt::user::create -admin]
           twt::user::login $user_info(email) $user_info(password)

	   # Create a new Faq
	   set faq_name [ad_generate_random_string]
	   faq::twt::new $faq_name

	   # Create a new Question_Answer
	   set question [ad_generate_random_string]
	   set answer [ad_generate_random_string]
	   faq::twt::new_Q_A $faq_name $question $answer
	  
	   # Edit a Question_Answer
	   set new_question [ad_generate_random_string]
	   set new_answer [ad_generate_random_string]
	   set response [faq::twt::edit_Q_A $faq_name $new_question $new_answer]
	   aa_display_result -response $response -explanation {Webtest for editing a Question in a Faq}
	   
	   twt::user::logout
       }           	
}

aa_register_case -cats {web smoke} -libraries tclwebtest tclwebtest_insert_after_Q_A_faq {

	A simple test case to faq package :  Insert After a Q&A. 

} {
	aa_run_with_teardown -test_code {
	    
	    tclwebtest::cookies clear
            # Login user
	    array set user_info [twt::user::create -admin]
            twt::user::login $user_info(email) $user_info(password)

	    # Create a new Faq
	    set faq_name [ad_generate_random_string]
	    faq::twt::new $faq_name

	    # Create a new Question_Answer
	    set question [ad_generate_random_string]
            set answer [ad_generate_random_string]
	    faq::twt::new_Q_A $faq_name $question $answer		
	    
	    # Insert after a Question_Answer
	    set response [faq::twt::insert_after_Q_A $faq_name]   
	    aa_display_result -response $response -explanation {Webtest for inserting a Question after a nother in a Faq}
	   
	    twt::user::logout
	}            	
}

aa_register_case -cats {web smoke} -libraries tclwebtest tclwebtest_preview_Q_A_faq {

    A simple test case to faq package :  Preview a Q&A. 

} {
	aa_run_with_teardown -test_code {  

	    tclwebtest::cookies clear
	    # Login user
	   array set user_info [twt::user::create -admin]
           twt::user::login $user_info(email) $user_info(password)
	
	    # Create a new Faq
	    set faq_name [ad_generate_random_string]
	    faq::twt::new $faq_name

	    # Create a new Question_Answer
	    set question [ad_generate_random_string]
	    set answer [ad_generate_random_string]
	    faq::twt::new_Q_A $faq_name $question $answer

	    # Preview a Question_Answer
	    set response [faq::twt::preview_Q_A $faq_name]
	    aa_display_result -response $response -explanation {Webtest for previewing a Question in a Faq}
	    
	    twt::user::logout
       }           	
}

aa_register_case -cats {web smoke} -libraries tclwebtest tclwebtest_swap_with_next_Q_A_faq {

    A simple test case to faq package : Swap With Next Q&A. 

} {
	aa_run_with_teardown -test_code {  
	
	    tclwebtest::cookies clear
	    # Login user
	    array set user_info [twt::user::create -admin]
	    twt::user::login $user_info(email) $user_info(password)

	    set faq_name [ad_generate_random_string]
	    faq::twt::new $faq_name

	    # Create a new Question_Answer
	    set question_1 [ad_generate_random_string]
	    set answer_1 [ad_generate_random_string]
	    faq::twt::new_Q_A $faq_name $question_1 $answer_1	
  
	    # Create a new Question_Answer
	    set question_2 [ad_generate_random_string]
	    set answer_2 [ad_generate_random_string]
	    faq::twt::new_Q_A $faq_name $question_2 $answer_2	
	   
	    # Swap with next Question_Answer
	    set response [faq::twt::swap_with_next_Q_A $faq_name]
	    aa_display_result -response $response -explanation {Webtest for swaping a question with a next in a Faq}
	   
	    twt::user::logout
       }
}
