ad_page_contract {
    Mockup
} {
}

set page_title "Prepare Report for Basic Legal Case"
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
        state1 {
            label "Initial Task"
            display_template {
                @tasks.state1;noquote@
            }
        }

        name { 
            label "Task"
            display_template {
                <if @tasks.edit_url@ not nil><a href="@tasks.edit_url@">@tasks.pretty_name@</a></if><else>@tasks.pretty_name@</else>
            }
        }
        state2 {
            label "Getting information from client"
            display_template {
                @tasks.state2;noquote@
            }
        }
        state3 {
            label "Researching Report"
            display_template {
                @tasks.state3;noquote@
            }
        }

        state4 {
            label "Editing Report"
            display_template {
                @tasks.state4;noquote@
            }
        }
        state5 {
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


multirow create tasks edit_url pretty_name state1 state2 state3 state4 state5

multirow append tasks "" "Initialize" "<input type=\"radio\" name=\"init\" checked>" "<input disabled type=\"checkbox\" disabled>" "<input disabled type=\"checkbox\">" "<input disabled type=\"checkbox\">"
multirow append tasks "" "Ask Client for information" "<input type=\"radio\" name=\"init\">" "<input type=\"checkbox\" name=\"init\" checked disabled>" "<input disabled type=\"checkbox\" disabled>" "<input disabled type=\"checkbox\">" 
multirow append tasks "" "Ask Client for more info" "<input type=\"radio\" name=\"init\">"  "<input disabled type=\"checkbox\">" "<input disabled type=\"checkbox\" checked>" "<input disabled type=\"checkbox\">"
multirow append tasks ""  "Visit the Library" "<input type=\"radio\" name=\"init\">" "<input disabled type=\"checkbox\">" "<input disabled type=\"checkbox\" checked>" "<input disabled type=\"checkbox\">"
multirow append tasks ""  "Consult Secretary" "<input type=\"radio\" name=\"init\">" "<input disabled type=\"checkbox\">" "<input disabled type=\"checkbox\" checked>" "<input disabled type=\"checkbox\">"
multirow append tasks "mockup-sim-ft-4" "Mentor Intervenes"  "<input type=\"radio\" name=\"init\">" "<input disabled type=\"checkbox\">" "<input disabled type=\"checkbox\" checked>" "<input disabled type=\"checkbox\">"
multirow append tasks "" "Consult Mentor"  "<input type=\"radio\" name=\"init\">" "<input disabled type=\"checkbox\">" "<input disabled type=\"checkbox\" checked>" "<input disabled type=\"checkbox\">"
multirow append tasks "" "Write Legal Advice"  "<input type=\"radio\" name=\"init\">" "<input disabled type=\"checkbox\">" "<input disabled type=\"checkbox\" checked>" "<input disabled type=\"checkbox\">"
multirow append tasks "" "Edit Report"  "<input type=\"radio\" name=\"init\">" "<input disabled type=\"checkbox\">" "<input disabled type=\"checkbox\">" "<input disabled type=\"checkbox\" checked>"


