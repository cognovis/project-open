ad_library {

    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
} 


namespace eval contact::complaint:: {}
namespace eval contacts::complaint:: {}

ad_proc -public contacts::complaint::install {
} {
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    
    Create the complaint content type for tracking complaints from customers
    
} {
    # Creation of contact_complaint_track table
    content::type::new -content_type "contact_complaint" \
        -pretty_name "Contact Complaint" \
        -pretty_plural "Contact Complaints" \
        -table_name "contact_complaint_track" \
        -id_column "complaint_id"
 
    # now set up the attributes that by default we need for the complaints
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "customer_id" \
	-datatype "integer" \
	-pretty_name "Customer ID" \
	-sort_order 1 \
	-column_spec "integer constraint contact_complaint_track_customer_fk
                               references parties(party_id) on delete cascade"
    
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "turnover" \
	-datatype "money" \
	-pretty_name "Turnover" \
	-sort_order 2 \
	-column_spec "float"
    
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "percent" \
	-datatype "integer" \
	-pretty_name "Percent" \
	-sort_order 3 \
	-column_spec "integer"
    
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "supplier_id" \
	-datatype "integer" \
	-pretty_name "Supplier ID" \
	-sort_order 4 \
	-column_spec "integer"
 
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "paid" \
	-datatype "money" \
	-pretty_name "Paid" \
	-sort_order 5 \
	-column_spec "float"
    
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "complaint_object_id" \
	-datatype "integer" \
	-pretty_name "Complaint Object ID" \
	-sort_order 6 \
	-column_spec "integer constraint contact_complaint_track_complaint_object_id_fk 
                               references acs_objects(object_id) on delete cascade"
    
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "state" \
	-datatype "string" \
	-pretty_name "State" \
	-sort_order 7 \
	-column_spec "varchar(7) constraint cct_state_ck
                               check (state in ('valid','invalid','open'))"
    
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "employee_id" \
	-datatype "integer" \
	-pretty_name "Employee ID" \
	-sort_order 8 \
	-column_spec "integer constraint contact_complaint_track_employee_fk
                               references parties(party_id) on delete cascade"
 
    content::type::attribute::new \
	-content_type "contact_complaint" \
	-attribute_name "refund_amount" \
	-datatype "money" \
	-pretty_name "Refund Amount" \
	-sort_order 9 \
	-column_spec "float"
}

ad_proc -public contact::complaint::new {
    {-complaint_id ""}
    {-title ""}
    -customer_id:required
    -turnover:required
    -percent:required
    {-description ""}
    -supplier_id:required
    -paid:required
    -complaint_object_id:required
    {-state "open"}
    {-employee_id ""}
    {-refund_amount ""}
} {
    Inserts a new complaint. Creates a new revision if complaint_id is not present, 
    otherwise creates a new item and revision for the complaint.
    
    @param complaint_id  The revision_id of the complaint_id, if not provided then it will create a new one.
    @param title         The title of the item.
    @param customer_id   
    @param turnover
    @param percent
    @param description
    @param supplier_id  
    @param paid
    @param complaint_object_id  The complaint is being made over this object_id 
    @param state
    @param employee_id
    @param refund_amount

} {
    if { [empty_string_p $complaint_id] } {
	# We create a new cr_item and revision
	set item_id [content::item::new \
			 -name $title \
			 -creation_user [ad_conn user_id] \
			 -package_id [ad_conn package_id] \
			 -description $description \
			 -title $title \
			 -is_live t]
	set complaint_id [content::item::get_live_revision -item_id $item_id]
	
    } else {
	# Create only a new revision
	set item_id [db_string get_item_id { }]
	set complaint_id [content::revision::new \
			      -item_id $item_id \
			      -title $title \
			      -description $description \
			      -creation_user [ad_conn user_id] \
			      -package_id [ad_conn package_id]]

    }
    
    # Insert extra information the table
    db_dml insert_complaint { }

}

ad_proc -public contact::complaint::check_name {
    -name:required
    {-parent_id "-100"}
    {-complaint_id ""}
} {
    Check if the name you are giving to the complaint already exists, if it does returns 1 otherwise returns 0
    
    @param name          The name of the item to check
    @param parent_id     The id of the parent item_id if exist, using -100 by default
    @param complaint_id  To figure out if is a new item or a new revision. If it's a revision, return 0   
} {
    if {![empty_string_p $complaint_id] } {
	return 0
    } else {
	return [db_string check_name { } -default 0]
    }
}