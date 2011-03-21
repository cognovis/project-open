ad_page_contract {
    Mockup
} {
}

set page_title "Editing 'Initialize'"
set context [list [list "." "Documentation"] [list "mockups.html" "Mockups"] [list "mockup-sim-ft-1" "Elementary Private Law"] $page_title]


template::list::create \
    -name states \
    -multirow states\
    -elements {
        name {
            label ""
        }
        state {
            label ""
            display_template {
                @states.state;noquote@
            }
        }
    }
     
multirow create states name state

multirow append states "Initialize" "<input type=\"checkbox\" disabled checked=1>"
multirow append states "Active" "<input type=\"checkbox\" disabled>"
multirow append states "Complete" "<input type=\"checkbox\" disabled\">"
        
set task_state_options [list [list "Pass/Fail" ""] [list "A B C D F" ""] [list "Completed/Cancelled/Out of Time"]]

set task_state_options_1 [list [list "Pass" ""] [list "Fail" ""]]

set agent_options [list [list "No Agent" ""] [list "Random" ""] [list "Inspect document"]]

ad_form -name task2 -form {
    {timeout:text
        {label "Time Limit"}
        {html {size 10}}
        {help_text "The action will automatically execute its Transformation this long after it is enabled. Leave blank to never timeout"}    }
}

ad_form -name agent -form {
    {timeout:text(radio)
        {label "Agent Action"}
        {options $agent_options}
    }
    {passstate:text(select)
        {label "Agent Pass State"}
        {options $task_state_options_1}
        {help_text "If agent returns true, set completion type to this"} 
    }
    {failstate:text(select)
        {label "Agent Fail State"}
        {options $task_state_options_1}
        {help_text "After time returns false, set completion type to this"}  
    }
}
