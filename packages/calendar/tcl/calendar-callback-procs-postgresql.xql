<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="callback::search::url::impl::cal_item.select_cal_item_package_url">
        <querytext>
            select site_node__url(min(node_id))
            from site_nodes
            where object_id = (select package_id
                               from cal_items ci, calendars
                               where cal_item_id = :object_id
			       and ci.on_which_calendar = calendars.calendar_id)
        </querytext>
    </fullquery>
</queryset>
