ad_page_contract { 
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
} {
    {return_url ""}
    {budget_id ""}
    project_id:integer,optional
}


set user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-budget.Edit_Budget]"

# Create the budget if it is not already there
if {![exists_and_not_null budget_id]} {
    if {[exists_and_not_null project_id]} {
        set page_title "[_ intranet-budget.New_Budget]"
        set budget [::im_budget::Budget create $project_id -parent_id $project_id -name "budget_${project_id}_${invoice_id}" -title "Budget für $project_name"]
        $budget save_new
        set budget_id [$budget item_id]
    } else {
        ad_return_error "Missing variable" "You need to provide either budget_id or project_id"
    }
}

set sub_navbar [im_costs_navbar "none" "/intranet-budget/" "" "" [list]] 

##################################
#  
# Financial Budget
#
##################################

set amount_new_json [util::json::gen [util::json::object::create [list title "New Budget" amount 0 type_id 3751]]]


set amount_baseParams [list action "get_costs" budget_id $budget_id]
set amount_sortInfo  [util::json::gen [util::json::object::create [list field "title" direction "ASC"]]]
set amount_columnDef [list item_id "string" title "string" amount "float" type_id "integer"]

set combo_name "cost_type"
set amount_category_combobox [extjs::RowEditor::ComboBox -combo_name "$combo_name" -form_name "amount_fm" \
                                  -optionDef [list 3751 "Investment Cost Budget" 3752 "One Time Cost Budget" 3753 "Repeating Cost Budget"]]

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
                       -baseParams [list action "save_costs" budget_id $budget_id]]

set amount_grid [extjs::RowEditor::GridPanel -prefix "amount_"  -new_title "Add Cost" -new_json "$amount_new_json" -autoExpandColumn "title" -title "Kosten" -height "400"]
set amount_cm [extjs::RowEditor::ColumnModel -prefix "amount_" -column_defs_json $column_defs]



##################################
#  
# hour Budget
#
##################################

set hour_new_json [util::json::gen [util::json::object::create [list title "New Time" hour 0 department_id 0]]]


set hour_baseParams [list action "get_hours" budget_id $budget_id]
set hour_sortInfo  [util::json::gen [util::json::object::create [list field "title" direction "ASC"]]]
set hour_columnDef [list item_id "string" title "string" amount "float" department_id "integer"]

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
                dataIndex: 'amount',
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
                       -baseParams [list action "save_hours" budget_id $budget_id]]

set hour_grid [extjs::RowEditor::GridPanel -prefix "hour_"  -new_title "Neue Stundenschätzung" -new_json "$hour_new_json" -autoExpandColumn "title" -title "Stunden"]
set hour_cm [extjs::RowEditor::ColumnModel -prefix "hour_" -column_defs_json $column_defs]


set Budget [::im_budget::Budget get_instance_from_db -item_id $budget_id]

# Setup the items for the form

ad_form -name budget_form -form {
    budget_id:key
    budget:float(currency)
    investment_costs:float(currency)
}


set budget_js [extjs::Form::Attribute::Currency -name "budget" -anchor "95%" -label "Budgetsumme" -default "[$Budget budget]"]
set invest_js [extjs::Form::Attribute::Currency -name "investment_costs" -anchor "95%" -label "Investitionskosten" -default "[$Budget investment_costs]"]
set single_js [extjs::Form::Attribute::Currency -name "single_costs" -anchor "95%" -label "Einmalkosten" -default "[$Budget single_costs]"]
set annual_js [extjs::Form::Attribute::Currency -name "annual_costs" -anchor "95%" -label "Jährliche Kosten" -default "[$Budget annual_costs]"]
set gain_js [extjs::Form::Attribute::Currency -name "economic_gain" -anchor "95%" -label "Wirtschaftlicher Nutzen" -default "[$Budget economic_gain]"]
set invest_exp_js [extjs::Form::Attribute::Htmleditor -name "investment_costs_explanation" -anchor "95%" -default "[$Budget investment_costs_explanation]"]
set single_exp_js [extjs::Form::Attribute::Htmleditor -name "single_costs_explanation" -anchor "95%" -default "[$Budget single_costs_explanation]"]
set annual_exp_js [extjs::Form::Attribute::Htmleditor -name "annual_costs_explanation" -anchor "95%" -default "[$Budget annual_costs_explanation]"]
set gain_exp_js [extjs::Form::Attribute::Htmleditor -name "economic_gain" -anchor "95%" -default "[$Budget economic_gain_explanation]"]
set budget_hours_js [extjs::Form::Attribute::Numeric -name "budget_hours" -label "Stundensumme" -default "[$Budget budget_hours]"]

if {0} {
# Columndef for the form
set form_columnDef [list budget float investment_costs float investment_costs_explanation string annual_costs float annual_costs_explanation string \
                        budget_hours float single_costs float single_costs_explanation string economic_gain float economic_gain_explanation string]
set form_store [extjs::DataStore::Json -url "budget-data" -baseParams [list action "get_budget" budget_id $budget_id] \
                    -columnDef "$form_columnDef" -prefix "fm_"]
}
# Drive the javascript
extjs::init
template::head::add_javascript -src "/extjs/examples/ux/RowEditor.js" -order 10
template::head::add_javascript -src "/extjs/Exporter-all.js" -order 20
template::head::add_javascript -src "/extjs/gistfile1.js" -order 40



