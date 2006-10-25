ad_page_contract {
    Mockup
} {
}

set page_title "Ask Info/Give Info"
set context [list [list "." "Documentation"] [list "mockups.html" "Mockups"] [list "mockup-sim-ft-1" "Elementary Private Law"] $page_title]

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
        state1 {
            label "Asking For Information"
            display_template {
                @tasks.state1;noquote@
            }
        }
        state2 {
            label "Waiting for response"
            display_template {
                @tasks.state2;noquote@
            }
        }
        state4 {
            label "Complete"
        }
        statea {
            label "<input type=\"submit\" value=\"Add a state\">"
            display_template {
            }
        }
        delete {
            sub_class narrow
            display_template {
                  <img src="/resources/acs-subsite/Delete16.gif" height="16" width="16" border="0" alt="Edit">
            }
        }
    }

multirow create tasks edit_url pretty_name state1 state2 state3 state4

multirow append tasks "" "Ask for infomation" "<input disabled type=\"checkbox\" checked disabled>" "<input disabled type=\"checkbox\">" 
multirow append tasks "mockup-sim-ft-6" "Respond to request" "<input disabled type=\"checkbox\">" "<input disabled type=\"checkbox\" checked>" 



template::list::create \
    -name counters \
    -multirow counters \
    -actions {"Add a Counter" ""} \
    -elements {
        name { 
            label "Counter"
        }
        values {
            label "Possible Values"
            display_template {
                <select>
                <option>A/B/C/D/F</option>
                <option>Pass/fail</option>
                <option>text</option>
                <option>number</option>
                </select>
            }
        }
        delete {
            sub_class narrow
            display_template {
                  <img src="/resources/acs-subsite/Delete16.gif" height="16" width="16" border="0" alt="Edit">
            }
        }
    }


multirow create counters name 

multirow append counters "Grade"


