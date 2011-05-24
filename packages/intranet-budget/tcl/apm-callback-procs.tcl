ad_library {
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
}

namespace eval im_budget {}

ad_proc -private im_budget::package_install {} {} {
    #
    # create classes
    # 
    apm_load_packages -force_reload -packages intranet-xotcl-dynfield
    ::im::dynfield::CrClass create Budget -superclass ::im::dynfield::CrItem \
        -pretty_name "Budget" -pretty_plural "Budgets" \
        -table_name "im_budgets" -id_column "budget_id" \
        -mime_type text/html -object_type "im_budget" \
        -slots {
            ::im::dynfield::CrAttribute create budget -sqltype float \
                -pretty_name "#intranet-budget.Budget#" -widget_name "currency"
            ::im::dynfield::CrAttribute create budget_hours -sqltype float \
                -pretty_name "#intranet-budget.Hours#"  -widget_name "numeric"
            ::im::dynfield::CrAttribute create budget_hours_explanation -sqltype text \
                -pretty_name "#intranet-budget.HoursExplanation#" -widget_name "richtext"
            ::im::dynfield::CrAttribute create economic_gain -sqltype float \
                -pretty_name "#intranet-budget.EconomicGain#" -widget_name "currency"
            ::im::dynfield::CrAttribute create economic_gain_explanation -sqltype text \
                -pretty_name "#intranet-budget.EconomicGainExplanation#" -widget_name "richtext"
            ::im::dynfield::CrAttribute create budget_item_revisions -sqltype text \
                -pretty_name "Budget Item Revisions" -widget_name "textbox_small"
            ::im::dynfield::CrAttribute create single_costs -sqltype float \
                -pretty_name "#intranet-budget.SingleCosts#" -widget_name "currency"
            ::im::dynfield::CrAttribute create single_costs_explanation -sqltype text \
                -pretty_name "#intranet-budget.SingleCostsExplanation#" -widget_name "richtext"
            ::im::dynfield::CrAttribute create investment_costs -sqltype float \
                -pretty_name "#intranet-budget.InvestmentCosts#" -widget_name "currency"
            ::im::dynfield::CrAttribute create investment_costs_explanation -sqltype text \
                -pretty_name "#intranet-budget.InvestmentCostsExplanation#" -widget_name "richtext"
            ::im::dynfield::CrAttribute create annual_costs -sqltype float \
                -pretty_name "#intranet-budget.AnnualCosts#" -widget_name "currency"
            ::im::dynfield::CrAttribute create annual_costs_explanation -sqltype text \
                -pretty_name "#intranet-budget.AnnualCostsExplanation#" -widget_name "richtext"
        }

    ::im::dynfield::CrClass create Hour -superclass ::im::dynfield::CrItem \
        -pretty_name "Budget Hours" -pretty_plural "Budget Hours" \
        -table_name "im_budget_hours" -id_column "hour_id" \
        -mime_type text/html -object_type "im_budget_hour" \
        -slots {
            ::im::dynfield::CrAttribute department_id -sqltype integer \
                -references "im_cost_centers(cost_center_id)" -widget_name "departments"
            ::im::dynfield::CrAttribute create hours -sqltype float -widget_name "numeric"
        }
    
    ::im::dynfield::CrClass create Cost -superclass ::im::dynfield::CrItem \
        -pretty_name "Budget Cost" -pretty_plural "Budget Costs" \
        -table_name "im_budget_costs" -id_column "fund_id" \
        -type_column "type_id" -type_category_type "Intranet Cost Type" \
        -mime_type text/html -object_type "im_budget_cost" \
        -slots {
            ::im::dynfield::CrAttribute create amount -sqltype float -widget_name "currency"
            ::im::dynfield::CrAttribute type_id -sqltype integer \
                -references "im_categories(category_id)" -widget_name "numeric"
        }

    ::im::dynfield::CrClass create Benefit -superclass ::im::dynfield::CrItem \
        -pretty_name "Budget Benefit" -pretty_plural "Budget Benefits" \
        -table_name "im_budget_benefits" -id_column "fund_id" \
        -type_column "type_id" -type_category_type "Intranet Benefit Type" \
        -mime_type text/html -object_type "im_budget_benefit" \
        -slots {
            ::im::dynfield::CrAttribute create amount -sqltype float -widget_name "currency"
            ::im::dynfield::CrAttribute type_id -sqltype integer \
                -references "im_categories(category_id)" -widget_name "numeric"
        }

    set object_types [db_list object_types "select object_type from acs_object_types where supertype ='::im::dynfield::CrItem'"]
    foreach object_type $object_types {
        ns_log Notice "intranet-dynfield/tcl/99-create-class-procs.tcl: ::im::dynfield::CrClass get_class_from_db -object_type $object_type"
        ::im::dynfield::CrClass get_class_from_db -object_type $object_type
    } 
    
    
}

ad_proc -private im_budget::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    After upgrade callback for intranet-cust-berendsen
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            0.2d4 0.2d5 {
                #
                # create classes
                # 
                ::im::dynfield::CrClass create Budget -superclass ::im::dynfield::CrItem \
                    -pretty_name "Budget" -pretty_plural "Budgets" \
                    -table_name "im_budgets" -id_column "budget_id" \
                    -mime_type text/html -object_type "im_budget" \
                    -slots {
                        ::im::dynfield::CrAttribute create budget -sqltype float \
                            -pretty_name "#intranet-budget.Budget#" -widget_name "currency"
                        ::im::dynfield::CrAttribute create budget_hours -sqltype float \
                            -pretty_name "#intranet-budget.Hours#"  -widget_name "numeric"
                        ::im::dynfield::CrAttribute create budget_hours_explanation -sqltype text \
                            -pretty_name "#intranet-budget.HoursExplanation#" -widget_name "richtext"
                        ::im::dynfield::CrAttribute create economic_gain -sqltype float \
                            -pretty_name "#intranet-budget.EconomicGain#" -widget_name "currency"
                        ::im::dynfield::CrAttribute create economic_gain_explanation -sqltype text \
                            -pretty_name "#intranet-budget.EconomicGainExplanation#" -widget_name "richtext"
                        ::im::dynfield::CrAttribute create budget_item_revisions -sqltype text \
                            -pretty_name "Budget Item Revisions" -widget_name "textbox_small"
                        ::im::dynfield::CrAttribute create single_costs -sqltype float \
                            -pretty_name "#intranet-budget.SingleCosts#" -widget_name "currency"
                        ::im::dynfield::CrAttribute create single_costs_explanation -sqltype text \
                            -pretty_name "#intranet-budget.SingleCostsExplanation#" -widget_name "richtext"
                        ::im::dynfield::CrAttribute create investment_costs -sqltype float \
                            -pretty_name "#intranet-budget.InvestmentCosts#" -widget_name "currency"
                        ::im::dynfield::CrAttribute create investment_costs_explanation -sqltype text \
                            -pretty_name "#intranet-budget.InvestmentCostsExplanation#" -widget_name "richtext"
                        ::im::dynfield::CrAttribute create annual_costs -sqltype float \
                            -pretty_name "#intranet-budget.AnnualCosts#" -widget_name "currency"
                        ::im::dynfield::CrAttribute create annual_costs_explanation -sqltype text \
                            -pretty_name "#intranet-budget.AnnualCostsExplanation#" -widget_name "richtext"
                    }
                
                ::im::dynfield::CrClass create Hour -superclass ::im::dynfield::CrItem \
                    -pretty_name "Budget Hours" -pretty_plural "Budget Hours" \
                    -table_name "im_budget_hours" -id_column "hour_id" \
                    -mime_type text/html -object_type "im_budget_hour" \
                    -slots {
                        ::im::dynfield::CrAttribute department_id -sqltype integer \
                            -references "im_cost_centers(cost_center_id)" -widget_name "departments"
                        ::im::dynfield::CrAttribute create hours -sqltype float -widget_name "numeric"
                    }
                
                ::im::dynfield::CrClass create Cost -superclass ::im::dynfield::CrItem \
                    -pretty_name "Budget Cost" -pretty_plural "Budget Costs" \
                    -table_name "im_budget_costs" -id_column "fund_id" \
                    -type_column "type_id" -type_category_type "Intranet Cost Type" \
                    -mime_type text/html -object_type "im_budget_cost" \
                    -slots {
                        ::im::dynfield::CrAttribute create amount -sqltype float -widget_name "currency"
                        ::im::dynfield::CrAttribute type_id -sqltype integer \
                            -references "im_categories(category_id)" -widget_name "numeric"
                    }
                ::im::dynfield::CrClass create Benefit -superclass ::im::dynfield::CrItem \
                    -pretty_name "Budget Benefit" -pretty_plural "Budget Benefits" \
                    -table_name "im_budget_benefits" -id_column "fund_id" \
                    -type_column "type_id" -type_category_type "Intranet Benefit Type" \
                    -mime_type text/html -object_type "im_budget_benefit" \
                    -slots {
                        ::im::dynfield::CrAttribute create amount -sqltype float -widget_name "currency"
                        ::im::dynfield::CrAttribute type_id -sqltype integer \
                            -references "im_categories(category_id)" -widget_name "numeric"
                    }
                
                set object_types [db_list object_types "select object_type from acs_object_types where supertype ='::im::dynfield::CrItem'"]
                foreach object_type $object_types {
                    ns_log Notice "intranet-dynfield/tcl/99-create-class-procs.tcl: ::im::dynfield::CrClass get_class_from_db -object_type $object_type"
                    ::im::dynfield::CrClass get_class_from_db -object_type $object_type
                } 
                
            }
            0.2d8 0.2d9 {
                #
                # create classes
                # 
                namespace eval im_budget {
                ::im::dynfield::CrClass create Benefit -superclass ::im::dynfield::CrItem \
                    -pretty_name "Budget Benefit" -pretty_plural "Budget Benefits" \
                    -table_name "im_budget_benefits" -id_column "fund_id" \
                    -type_column "type_id" -type_category_type "Intranet Benefit Type" \
                    -mime_type text/html -object_type "im_budget_benefit" \
                    -slots {
                        ::im::dynfield::CrAttribute create amount -sqltype float -widget_name "currency"
                        ::im::dynfield::CrAttribute type_id -sqltype integer \
                            -references "im_categories(category_id)" -widget_name "numeric"
                    }
                }
            }
        }
            
}