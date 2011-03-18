# 

::xo::library doc {
    intranet-budget - main library classes and objects

    @creation-date 2011-03-13
    @author Malte Sussdorff
}

::xo::db::CrItem instproc json_object {} {
    set class_name [my info class]
    set slots [$class_name info slots]
    set json_list [list]
    foreach slot $slots {
        set attribute_name [$slot name]
        lappend json_list $attribute_name
        lappend json_list [my set $attribute_name]
    }
    return [util::json::object::create $json_list]
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
          ::xo::db::CrAttribute create budget -sqltype integer \
              -pretty_name "#intranet-budget.Budget#"
          ::xo::db::CrAttribute create budget_hours -sqltype integer \
              -pretty_name "#intranet-budget.Hours#"
          ::xo::db::CrAttribute create budget_hours_explanation -sqltype text \
              -pretty_name "#intranet-budget.HoursExplanation#"
          ::xo::db::CrAttribute create economic_gain -sqltype integer \
              -pretty_name "#intranet-budget.EconomicGain#"
          ::xo::db::CrAttribute create economic_gain_explanation -sqltype text \
              -pretty_name "#intranet-budget.EconomicGainExplanation#"
          ::xo::db::CrAttribute create budget_item_revisions -sqltype text \
              -pretty_name "Budget Item Revisions"
          ::xo::db::CrAttribute create single_costs -sqltype integer \
              -pretty_name "#intranet-budget.SingleCosts#"
          ::xo::db::CrAttribute create single_costs_explanation -sqltype text \
              -pretty_name "#intranet-budget.SingleCostsExplanation#"
          ::xo::db::CrAttribute create investment_costs -sqltype integer \
              -pretty_name "#intranet-budget.InvestmentCosts#"
          ::xo::db::CrAttribute create investment_costs_explanation -sqltype text \
              -pretty_name "#intranet-budget.InvestmentCostsExplanation#"
          ::xo::db::CrAttribute create annual_costs -sqltype integer \
              -pretty_name "#intranet-budget.AnnualCosts#"
          ::xo::db::CrAttribute create annual_costs_explanation -sqltype text \
              -pretty_name "#intranet-budget.AnnualCostsExplanation#"

      }

  ::xo::db::CrClass create BudgetElement -superclass ::xo::db::CrItem \
      -pretty_name "Budget Element" -pretty_plural "Budget Elements" \
      -table_name "im_budget_elements" -id_column "element_id" \
      -mime_type text/html \
      -slots {
          ::xo::db::CrAttribute type_id -sqltype integer \
              -references "im_categories(category_id)"
          ::xo::db::CrAttribute create amount -sqltype float
      }
  
  ::xo::db::CrClass create Hour -superclass ::im_budget::BudgetElement \
      -pretty_name "Budget Hours" -pretty_plural "Budget Hours" \
      -table_name "im_budget_hours" -id_column "hour_id" \
      -mime_type text/html \
      -slots {
          ::xo::db::CrAttribute department_id -sqltype integer \
              -references "im_cost_centers(cost_center_id)"
      }
  
  ::xo::db::CrClass create Cost -superclass ::im_budget::BudgetElement \
      -pretty_name "Budget Cost" -pretty_plural "Budget Costs" \
      -table_name "im_budget_costs" -id_column "fund_id" \
      -mime_type text/html 

}

