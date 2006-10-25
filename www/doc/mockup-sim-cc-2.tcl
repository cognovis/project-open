ad_page_contract {
    Mockup
} {
}

set page_title "Editing a single task: Respond to Deposition"
set context [list [list "." "Documentation"] [list "mockups.html" "Mockups"] [list "mockup-sim-cc-1" "Sim Use Case as collection of FSMs"] $page_title]

set role_options [list [list   "Salesperson" "foo"] [list   "Salesperson's Lawyer" "foo"] [list   "Customer" "foo"] [list   "Customer's Lawyer" "foo"] [list   "Secretary1" "foo"] [list   "Secretary2" "foo"] [list   "Partner1" "foo"] [list "Partner2" "foo"]]

set task_state_options [list [list "Pass/Fail" ""] [list "A B C D F" ""] [list "Completed/Cancelled/Out of Time"]]

set task_state_options_1 [list [list "Pass" ""] [list "Fail" ""]]

set agent_options [list [list "No Agent" ""] [list "Random" ""] [list "Inspect document"]]

ad_form -name task -form {
    {action_id:key}
    {workflow_id:integer(hidden)
    }
    {name:text
        {label "Task Name"}
        {html {size 20}}
        {value "Respond to Deposition"}
    }
    {assigned_role:text(select)
        {label "Assigned To"}
        {options $role_options}
    }
    {recipient_role:text(select)
        {label "Recipient"}
        {options $role_options}
    }
    {description:richtext,optional
        {label "Task Description"}
        {html {cols 60 rows 8}}
    }
    {completiontype:text(select)
        {label "Completion Codes"}
        {options $task_state_options}
    }
}

template::list::create \
    -name depends \
    -multirow depends \
    -elements {
        logic {
            sub_class narrow
        }
        task { 
            label "Task"
        }
        state { 
            label "State"
        }
        delete {
            sub_class narrow
            display_template {
                  <img src="/resources/acs-subsite/Delete16.gif" height="16" width="16" border="0" alt="Edit">
            }
        }
    }

multirow create depends logic task state

multirow append depends "" "Depose Customer" "Completed"
multirow append depends "AND" "Deliver Report to Secretary" "Completed"

ad_form -name task2 -form {
    {timeout:text
        {label "Time Limit"}
        {html {size 10}}
        {help_text "Task will be disabled this long after being enabled.  Leave blank to never timeout"}    }
    {nextstate:text(select)
        {label "Completion Type"}
        {options $task_state_options_1}
        {help_text "After time limit, set completion type to this (choices will vary depending on "}    }
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
