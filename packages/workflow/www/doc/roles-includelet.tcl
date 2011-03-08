template::list::create \
    -name roles \
    -multirow roles \
    -actions {"Add a Role" ""} \
    -elements {
        edit {
            sub_class narrow
            display_template {
                <img src="/resources/acs-subsite/Edit16.gif" height="16" width="16" border="0" alt="Edit">
            }
        }
        pretty_name { 
            label "Role"
            display_col pretty_name
        }
        delete {
            sub_class narrow
            display_template {
                  <img src="/resources/acs-subsite/Delete16.gif" height="16" width="16" border="0" alt="Edit">
            }
        }
    }

multirow create roles pretty_name
multirow append roles "Salesperson"
multirow append roles "Salesperson's Lawyer"
multirow append roles "Customer"
multirow append roles "Customer's Lawyer"
multirow append roles "Secretary1"
multirow append roles "Secretary2"
multirow append roles "Partner1"
multirow append roles "Partner2"
