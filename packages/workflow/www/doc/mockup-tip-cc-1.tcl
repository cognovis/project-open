ad_page_contract {
    Mockup
} {
}

set page_title "Sim Use Case as collection of FSMs"
set context [list [list "." "Documentation"] [list "mockups.html" "Mockups"] $page_title]

template::list::create \
    -name tasks \
    -multirow tasks \
    -actions {"Add a Task" ""} \
    -elements {
        edit {
            sub_class narrow
            display_template {
                <img src="/resources/acs-subsite/Edit16.gif" height="16" width="16" border="0" alt="Edit">
            }
        }
        name { 
            label "Task"
            display_template {
                <if @tasks.edit_url@ not nil><a href="@tasks.edit_url@">@tasks.pretty_name@</a></if><else>@tasks.pretty_name@</else>
            }
        }
        assigned_name {
            label "Assigned to"
        }
        recipient_name {
            label "Recipient"
        }
        delete {
            sub_class narrow
            display_template {
                  <img src="/resources/acs-subsite/Delete16.gif" height="16" width="16" border="0" alt="Edit">
            }
        }
    }


multirow create tasks edit_url pretty_name assigned_name recipient_name

multirow append tasks "" "Depose Salesperson" "Customer's Lawyer" "Salesperson"
multirow append tasks "" "Depose Customer" "Salesperson's Lawyer" "Customer"
multirow append tasks "" "Respond to Deposition" "Salesperson" "Customer's Lawyer"
multirow append tasks "mockup-sim-cc-2" "Respond to Deposition" "Customer" "Salesperson's Lawyer"
multirow append tasks "" "Intervene" "Partner2" "Salesperson's Lawyer"
multirow append tasks "" "Intervene" "Partner1" "Customer's Lawyer"
multirow append tasks "" "Respond to Intervention" "Salesperson's Lawyer" "Partner2"
multirow append tasks "" "Respond to Intervention" "Customer's Lawyer" "Partner1" 
multirow append tasks "" "Deliver Report to Secretary" "Customer's Lawyer" "Secretary1" 
multirow append tasks "" "Deliver Report to Secretary" "Salesperson's Lawyer" "Secretary2" 
multirow append tasks "" "Get info from Salesperson's Lawyer" "Customer's Lawyer" "Salesperson's Lawyer" 
multirow append tasks "" "Get info from Customer's Lawyer" "Salesperson's Lawyer" "Customer's Lawyer" 
multirow append tasks "" "Respond to Customer's Lawyer" "Salesperson's Lawyer" "Customer's Lawyer" 
multirow append tasks "" "Respond to Salesperson's Lawyer" "Customer's Lawyer" "Salesperson's Lawyer" 
multirow append tasks "" "Submit Final Report" "Salesperson's Lawyer" "" 
multirow append tasks "" "Submit Final Report" "Customer's Lawyer" "" 