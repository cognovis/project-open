<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="callback::search::url::impl::cal_item.select_cal_item_package_url">
        <querytext>
            select site_node.url(min(node_id))
            from site_nodes
            where object_id = (select package_id
                               from cal_items ci, calendars
                               where cal_item_id = :cal_item_id
			       and ci.on_which_calendar = calendars.calendar_id)
        </querytext>
    </fullquery>
</queryset>
