#---------------------------------------------------------------------
# mockup task form
#---------------------------------------------------------------------

ad_form -name task -form {
    {action_id:key}
    {workflow_id:integer(hidden)
        {value $workflow_id}
    }
    {name:text
        {label "Task Name"}
        {html {size 20}}
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
}