
ad_page_contract {
    delete all occurences of a recurring item
    
    @author Ben Adida (ben@openforce.net)
    @creation-date April 25, 2002
} {
    recurrence_id
    {return_url "./"}
}

calendar::item::delete_recurrence -recurrence_id $recurrence_id

ad_returnredirect $return_url
