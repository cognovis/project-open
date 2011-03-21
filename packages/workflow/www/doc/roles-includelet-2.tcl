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
multirow append roles "Asker"
multirow append roles "Giver"
