ad_page_contract {

    list all attributes avaiable, and let the user edit edit permissions, regroup, etc.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$

} {
   groupby:optional
    orderby:optional
    {format "normal"}
    {status "normal"}
}

set title "Widgets"
set context [list [list "attributes" "Attributes"] $title]


list::create \
    -name entries \
    -multirow entries \
    -key course_id \
    -row_pretty_plural "Attributes" \
    -checkbox_name checkbox \
    -selected_format $format \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -pass_properties {
        variable
    } -actions {
    } -bulk_actions {
    } -elements {
        description {
            display_col description
            label "Description"
        }
        widget {
            display_col widget
            label "Widget"
        }
        datatype {
            display_col datatype
            label "Datatype"
        }
        html {
            display_col html
            label "HTML"
        }
        format {
            display_col format
            label "Format"
        }

    } -filters {
    } -groupby {
    } -orderby {
    } -formats {
        normal {
            label "Table"
            layout table
            row {
                description {}
                widget {}
                datatype {}
                html {}
                format {}
            }
        }

    }



db_multirow -unclobber entries get_widgets ""


ad_return_template
