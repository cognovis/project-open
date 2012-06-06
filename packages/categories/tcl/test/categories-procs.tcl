ad_library {
    Automated tests.

    @author Simon Carstensen
    @creation-date 15 November 2003
    @cvs-id $Id$
}

aa_register_case category_tree_add {
    Test the category_tree::add proc.
} {    

    aa_run_with_teardown \
        -rollback \
        -test_code {
           
            #Create tree
            set tree_id [category_tree::add -name "foo"]

            set success_p [db_string success_p {
                select 1 from category_trees where tree_id = :tree_id
            } -default "0"]

            aa_equals "tree was created succesfully" $success_p 1
        }
}

aa_register_case category_add {
    Test the category::add proc.
} {    

    aa_run_with_teardown \
        -rollback \
        -test_code {
           
            #Create tree
            set tree_id [category_tree::add -name "foo"]

            # Create category
            set category_id [category::add \
                                 -tree_id $tree_id \
                                 -parent_id "" \
                                 -name "foo"]

            set success_p [db_string success_p {
                select 1 from categories where category_id = :category_id
            } -default "0"]

            aa_equals "category was created succesfully" $success_p 1
        }
}

aa_register_case category_delete {
    Test the category::delete proc.
} {    

    aa_run_with_teardown \
        -rollback \
        -test_code {
 
            #Create tree
            set tree_id [category_tree::add -name "foo"]

            # Create category
            set category_id [category::add \
                                 -tree_id $tree_id \
                                 -parent_id "" \
                                 -name "foo"]

            # Delete category
            category::delete -batch_mode $category_id
            
            set success_p [db_string success_p {
                select 0 from categories where category_id = :category_id
            } -default "1"]

            aa_equals "category was deleted succesfully" $success_p 1
        }
}
