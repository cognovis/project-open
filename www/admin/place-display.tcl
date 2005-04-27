# packages/acs-workflow/www/admin/place-display.tcl
# @author Lars Pind (lars@pinds.com)
# @creation-date November 21, 2000
# @cvs-id $Id$
#
# Expects:
#    workflow (magic)
#    place_key
#    selected_transition_key
#    selected_place_key
# Returns:
#    place:onerow(place_key, place_name, url, num, selected_p)

# place:onerow(place_key, place_name, edit_url, delete_url, arc_add_url, arc_delete_url, num)

set place(place_key) $place_key
set place(place_name) $workflow(place,$place_key,place_name)
set place(num) $workflow(place,$place_key,sort_order)
set place(selected_p) [string equal $place_key $selected_place_key]
set place(url) $workflow(place,$place_key,url)

ad_return_template



