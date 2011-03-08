# Expects "title" and "header" and "context_bar"

if { ![info exists title] } {
    set title ""
} 

if { ![info exists header] } {
    set header $title
}

if { ![info exists notification_link] } {
    set notification_link ""
}

ad_return_template
