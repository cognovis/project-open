# This is the template for a single bookmark icon
request create
request set_param mount_point -datatype keyword
request set_param id -datatype keyword

set img_checked "[ad_conn package_url]resources/checked.gif"
set img_unchecked "[ad_conn package_url]resources/unchecked.gif"

set package_url [ad_conn package_url]
set clipboardfloats_p [clipboard::floats_p]
