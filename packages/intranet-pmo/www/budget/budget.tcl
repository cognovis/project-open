ad_page_contract { 
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
} {
    {return_url ""}
    {budget_id ""}
    {project_id ""}
}


set user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-pmo.Edit_Budget]"

# Create the budget if it is not already there
if {![exists_and_not_null budget_id]} {
    if {[exists_and_not_null project_id]} {
        # Search the budget_id
        set budget_id [db_string budget_id "select item_id from cr_items where parent_id = :project_id and content_type = 'im_budget' limit 1" -default ""]
        if {$budget_id eq ""} {
            set page_title "[_ intranet-pmo.New_Budget]"
	    set budget_id [content::item::new -parent_id $project_id -name "budget_${project_id}" -title "Budget for $project_id" -content_type "im_budget"]
        }
    } else {
        ad_return_error "Missing variable" "You need to provide either budget_id or project_id"
    }
}

if {$project_id eq ""} {
    set project_id [db_string project_id "select parent_id from cr_items where item_id = :budget_id"]
}

# ---------------------------------------------------------------
# Project Menu Navbar
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]

set sub_navbar [im_sub_navbar \
    -components \
    -base_url "/intranet/projects/view?project_id=$project_id" \
    $project_menu_id \
    $bind_vars "" "pagedesriptionbar" "project_budget"] 


# Dirty Trick to reload the form after we changed a row
# The After success part will be executed as part of the row editor
# for each Grid once a row has been successfully saved.
set after_success "budget_form.getForm().load(\{
        url:'budget-data',
        params: \{
            action: 'get_calculated_budget', budget_id: $budget_id \}
    \});"

##################################
#  
# Financial Budget
#
##################################

set amount_new_json [util::json::gen [util::json::object::create [list title "#intranet-pmo.Add_Cost#" amount 0 type_id 3751]]]


set amount_baseParams [list action "get_costs" budget_id $budget_id]
set amount_sortInfo  [util::json::gen [util::json::object::create [list field "title" direction "ASC"]]]
set amount_columnDef [list item_id "string" title "string" amount "float" type_id "integer"]

set combo_name "cost_type"
set amount_category_combobox [intranet_extjs::combobox::categories -parent_id 3750 -combo_name $combo_name -form_name "amount_fm"]

# set the column_defs

set column_defs "
            \{ // Not Sure yet if we actually need this or if it is already implicit in the grid....
                header:'#',
                readOnly: true,
                dataIndex: 'item_id',
                width: 50,
                hidden: true
            \}, \{
                id: 'title',
                header: '#intranet-core.Description#',
                dataIndex: 'title',
                width: 220,
                // use shorthand alias defined above
                editor: new amount_fm.TextField(\{
                    allowBlank: false
                \})
            \}, \{
                header: '#intranet-cost.Type#',
                dataIndex: 'type_id',
                width: 130,
                editor: $combo_name,
                renderer: Ext.util.Format.comboRenderer($combo_name) // pass combo instance to reusable renderer
            \},  \{
                header: '#intranet-cost.Amount#',
                dataIndex: 'amount',
                width: 70,
                align: 'right',
                renderer: Ext.util.Format.Currency,
                editor: new amount_fm.NumberField(\{
                    decimalSeparator: ','
                \})
            \}
"

set amount_store [extjs::DataStore::Json -url "budget-data" -baseParams "$amount_baseParams" -root "items" -id_column "item_id" \
                      -columnDef "$amount_columnDef" -sortInfo_json "$amount_sortInfo" -prefix "amount_"]

set amount_editor [extjs::RowEditor::Editor -prefix "amount_" -url "budget-data" -columnDef "$amount_columnDef" \
                       -baseParams [list action "save_costs" budget_id $budget_id] \
                       -after_success $after_success]

set amount_grid [extjs::RowEditor::GridPanel -prefix "amount_"  -new_title "Add Cost" -new_json "$amount_new_json" -autoExpandColumn "title" -title "Kosten"]
set amount_cm [extjs::RowEditor::ColumnModel -prefix "amount_" -column_defs_json $column_defs]




##################################
#  
# Economic Benefit
#
##################################

set benefit_new_json [util::json::gen [util::json::object::create [list title "#intranet-pmo.Add_Benefit#" benefit 0 type_id 3760]]]

set benefit_baseParams [list action "get_benefits" budget_id $budget_id]
set benefit_sortInfo  [util::json::gen [util::json::object::create [list field "title" direction "ASC"]]]
set benefit_columnDef [list item_id "string" title "string" amount "float"]


# set the column_defs

set column_defs "
            \{ // Not Sure yet if we actually need this or if it is already implicit in the grid....
                header:'#',
                readOnly: true,
                dataIndex: 'item_id',
                width: 50,
                hidden: true
            \}, \{
                id: 'title',
                header: '#intranet-core.Description#',
                dataIndex: 'title',
                width: 220,
                // use shorthand alias defined above
                editor: new benefit_fm.TextField(\{
                    allowBlank: false
                \})
            \},  \{
                header: '#intranet-pmo.Benefits#',
                dataIndex: 'amount',
                width: 70,
                align: 'right',
                renderer: Ext.util.Format.Currency,
                editor: new benefit_fm.NumberField(\{
                    decimalSeparator: ','
                \})
            \}
"

set benefit_store [extjs::DataStore::Json -url "budget-data" -baseParams "$benefit_baseParams" -root "items" -id_column "item_id" \
                      -columnDef "$benefit_columnDef" -sortInfo_json "$benefit_sortInfo" -prefix "benefit_"]

set benefit_editor [extjs::RowEditor::Editor -prefix "benefit_" -url "budget-data" -columnDef "$benefit_columnDef" \
                       -baseParams [list action "save_benefits" budget_id $budget_id] \
                        -after_success $after_success]

set benefit_grid [extjs::RowEditor::GridPanel -prefix "benefit_"  -new_title "[_ intranet-pmo.Add_Benefit]" -new_json "$benefit_new_json" -autoExpandColumn "title" -title "[_ intranet-pmo.Benefits]"]
set benefit_cm [extjs::RowEditor::ColumnModel -prefix "benefit_" -column_defs_json $column_defs]



##################################
#  
# hour Budget
#
##################################

set hour_new_json [util::json::gen [util::json::object::create [list title "#intranet-pmo.New_hour_estimate#" hour 0 department_id 0]]]


set hour_baseParams [list action "get_hours" budget_id $budget_id]
set hour_sortInfo  [util::json::gen [util::json::object::create [list field "title" direction "ASC"]]]
set hour_columnDef [list item_id "string" title "string" hours "float" department_id "integer"]

set combo_name "department"
set department_combobox [extjs::RowEditor::ComboBox -combo_name "$combo_name" -form_name "hour_fm" \
                             -sql "select cost_center_id, cost_center_name from im_cost_centers order by cost_center_id"]

# set the column_defs

set column_defs "
            \{ // Not Sure yet if we actually need this or if it is already implicit in the grid....
                header:'#',
                readOnly: true,
                dataIndex: 'item_id',
                width: 50,
                hidden: true
            \}, \{
                id: 'title',
                header: '#intranet-core.Description#',
                dataIndex: 'title',
                width: 220,
                // use shorthand alias defined above
                editor: new hour_fm.TextField(\{
                    allowBlank: false
                \})
            \}, \{
                header: '#intranet-core.Department#',
                dataIndex: 'department_id',
                width: 200,
                editor: $combo_name,
                renderer: Ext.util.Format.comboRenderer($combo_name) // pass combo instance to reusable renderer
            \},  \{
                header: '#intranet-timesheet2.Hours#',
                dataIndex: 'hours',
                width: 70,
                align: 'right',
                editor: new hour_fm.NumberField(\{
                    allowDecimals: false,
                    allowNegative: false
                \})
            \}
"

set hour_store [extjs::DataStore::Json -url "budget-data" -baseParams "$hour_baseParams" -root "items" -id_column "item_id" \
                      -columnDef "$hour_columnDef" -sortInfo_json "$hour_sortInfo" -prefix "hour_"]

set hour_editor [extjs::RowEditor::Editor -prefix "hour_" -url "budget-data" -columnDef "$hour_columnDef" \
                     -baseParams [list action "save_hours" budget_id $budget_id] \
                     -after_success $after_success
                    ]

set hour_grid [extjs::RowEditor::GridPanel -prefix "hour_"  -new_title "Neue Stundenschätzung" -new_json "$hour_new_json" -autoExpandColumn "title" -title "Stunden"]
set hour_cm [extjs::RowEditor::ColumnModel -prefix "hour_" -column_defs_json $column_defs]


# Setup the items for the form
set budget_js [extjs::Form::Attribute::Currency -name "budget" -anchor "95%" -label "Budgetsumme"]
set invest_js [extjs::Form::Attribute::Currency -name "investment_costs" -anchor "95%" -label "Investitionskosten"]
set single_js [extjs::Form::Attribute::Currency -name "single_costs" -anchor "95%" -label "Einmalkosten"]
set annual_js [extjs::Form::Attribute::Currency -name "annual_costs" -anchor "95%" -label "Jährliche Kosten"]
set gain_js [extjs::Form::Attribute::Currency -name "economic_gain" -anchor "95%" -label "Wirtschaftlicher Nutzen"]
set invest_exp_js [extjs::Form::Attribute::Htmleditor -name "investment_costs_explanation" -anchor "95%"]
set single_exp_js [extjs::Form::Attribute::Htmleditor -name "single_costs_explanation" -anchor "95%"]
set annual_exp_js [extjs::Form::Attribute::Htmleditor -name "annual_costs_explanation" -anchor "95%"]
set gain_exp_js [extjs::Form::Attribute::Htmleditor -name "economic_gain_explanation" -anchor "95%"]
set budget_hours_js [extjs::Form::Attribute::Number -name "budget_hours" -label "Stundensumme"]

# Drive the javascript
extjs::init
template::head::add_javascript -src "/extjs/ExtJS3/examples/ux/RowEditor.js" -order 9
template::head::add_javascript -src "/extjs/ux-numeric.js" -order 20

# Approve button for the PMO
if {[im_permission $user_id "approve_budgets"]} {
    set pmo_approve_js ",{
            text: '#intranet-pmo.Approve#',
            handler:function(){
                budget_form.getForm().load({
                    url:'budget-data',
                    params: {action: 'approve_budget', budget_id: '$budget_id'}
                });
            }
        }"
} else {
    set pmo_approve_js ""
}
