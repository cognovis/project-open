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
      -table_name "im_budget" -id_column "budget_id" \
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

}