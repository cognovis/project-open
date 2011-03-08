<tr>
    <if @place.selected_p@ eq 1><td bgcolor="#ccccff"></if>
    <else><td></else>
        (@place.num@)
        <if @place.url@ not nil><a href="@place.url@">@place.place_name@</a></if>
        <else>@place.place_name@</else>
    </td>
</tr>