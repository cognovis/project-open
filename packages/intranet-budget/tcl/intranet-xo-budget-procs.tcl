# 

::xo::library doc {
    intranet-budget - main library classes and objects

    @creation-date 2011-03-13
    @author Malte Sussdorff
}

namespace eval ::im_budget {
  #
  # create classes
  # 
  ::xo::db::CrClass create Budget -superclass ::xo::db::CrItem \
      -pretty_name "Budget" -pretty_plural "Budgets" \
      -table_name "im_budgets" -id_column "budget_id" \
      -mime_type text/html \
      -slots {
          ::xo::db::CrAttribute create approver_id -sqltype integer \
              -references "users(user_id)" -pretty_name "#intranet-budget.Approver#"
          ::xo::db::CrAttribute create budget_status_id \
              -references "im_categories(category_id)" -sqltype integer \
              -help_text "" -pretty_name "#intranet-core.Status#"
          ::xo::db::CrAttribute create budget_type_id \
              -references "im_categories(category_id)" -sqltype integer \
              -help_text "" -pretty_name "#intranet-core.Type#"
          ::xo::Attribute create name \
              -required false ;#true 
          ::xo::Attribute create title \
              -required false ;#true
      }

  ::xo::db::CrClass create BudgetElement -superclass ::xo::db::CrItem \
      -pretty_name "Budget Element" -pretty_plural "Budget Elements" \
      -table_name "im_budget_elements" -id_column "element_id" \
      -mime_type text/html

  ::xo::db::CrClass create BudgetHours -superclass ::im_budget::BudgetElement \
      -pretty_name "Budget Hours" -pretty_plural "Budget Hours" \
      -table_name "im_budget_hours" -id_column "hours_id" \
      -mime_type text/html \
      -slots {
          ::xo::db::CrAttribute create hours -sqltype float
          ::xo::db::CrAttribute department_id -sqltype integer \
              -references "im_cost_centers(cost_center_id)"
      }
  
  ::xo::db::CrClass create BudgetCosts -superclass ::im_budget::BudgetElement \
      -pretty_name "Budget Costs" -pretty_plural "Budget Costs" \
      -table_name "im_budget_costs" -id_column "costs_id" \
      -mime_type text/html \
      -slots {
          ::xo::db::CrAttribute create amount -sqltype float
          ::xo::db::CrAttribute cost_type_id -sqltype integer \
              -references "im_categories(category_id)"
      }

  ad_proc -public upgrade {
  } {
      upgrade procedure
  } {
      db_foreach project_info "select distinct project_id, im_name_from_id(project_id) as project_name,invoice_id from im_invoice_items where project_id is not null" {
          
          #get the project
          set budget_id [content::item::get_id_by_name -name "budget_${project_id}_${invoice_id}" -parent_id $project_id]
          
          if {$budget_id eq ""} {
              set budget [::im_budget::Budget create $project_id -parent_id $project_id -name "budget_${project_id}_${invoice_id}" -title "Budget für $project_name"]
              $budget save_new
          }
      }
      
      db_foreach invoice_item "select item_name, item_id, item_units*price_per_unit as amount, project_id, invoice_id, item_material_id from im_invoice_items where item_material_id is not null and project_id is not null" {
          set budget_id [content::item::get_id_by_name -name "budget_${project_id}_${invoice_id}" -parent_id $project_id]
          switch $item_material_id {
              33361 {set cost_type_id 3751}
              33362 {set cost_type_id 3753}
              33359 {set cost_type_id 3752}
          }

          if {$budget_id ne ""} {
              set budget_item [::im_budget::BudgetCosts create $item_id -parent_id $budget_id -name "budget_costs_${item_id}" -title "$item_name" \
                               -amount "$amount" -cost_type_id cost_type_id]
              $budget_item save_new
          } else {
              ds_comment "error::: $item_id"
          } 

      }

      
  }
}

