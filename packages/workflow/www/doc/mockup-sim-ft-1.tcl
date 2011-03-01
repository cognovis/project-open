ad_page_contract {
    Mockup
} {
}

set page_title "Sim Use Case as FSM Tree"
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
        state1 {
            label "Initialize"
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
            label "Active"
            display_template {
                @tasks.state2;noquote@
            }
        }
        state3 {
            label "Complete"
            display_template {
                @tasks.state3;noquote@
            }
        }
        statea {
            label "<input type=\"submit\" value=\"Add a state\">"
            display_template {
            }
        }

        delete {
            sub_class narrow
            display_template {
                <if @tasks.pretty_name@ ne \"Initialize\">
                  <img src="/resources/acs-subsite/Delete16.gif" height="16" width="16" border="0" alt="Edit">
</if>
            }
        }
    }


multirow create tasks edit_url pretty_name state1 state2 state3
multirow append tasks "mockup-sim-ft-7" "Initialize" "<input type=\"radio\" name=\"init\" checked>" "<input type=\"checkbox\">" "<input type=\"checkbox\">"
multirow append tasks "mockup-sim-ft-2" "First Lawyer's task" "<input type=\"radio\" name=\"init\">" "<input type=\"checkbox\" checked=1>" "<input type=\"checkbox\""
multirow append tasks "" "Second Lawyer's task" "<input type=\"radio\" name=\"init\">" "<input type=\"checkbox\">" "<input type=\"checkbox\" checked=1>" ""

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


