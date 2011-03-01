ad_page_contract { 
    Main category display page 
    @author Jeff Davis (davis@xarg.net)
    @cvs-id $Id: list-categories.tcl,v 1.1 2005/03/10 18:27:41 rob Exp $
} {
    {cat:trim,integer {}}
    {orderby "object_title"}
}

set cat_name [category::get_names $cat]

ad_return_template
