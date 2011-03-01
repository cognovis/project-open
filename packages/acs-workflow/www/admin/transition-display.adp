<multiple name="table">
<tr>
    <if @table.input_place_key@ not nil>
        <if @table.input_place_selected_p@ eq 1><td align="right" bgcolor="#ccccff"></if>
	    <else><td align="right"></else>
        (@table.input_place_num@)
        <if @table.input_place_url@ not nil><a href="@table.input_place_url@">@table.input_place_name@</a></if>
	    <else>@table.input_place_name@</else>
        </td>
        <td><img src="../greyarrow.gif"></td>
    </if>
    <else>
	    <td colspan=2>&nbsp;</td>
    </else>
    
    <if @table.transition_key@ not nil>
        <if @table.transition_trigger_type@ eq "user">
            <if @table.transition_selected_p@ eq 1><th align="center" bgcolor="#ccccff" rowspan="@table:rowcount@"></if>
            <else><th align="center" bgcolor="#dddddd" rowspan="@table:rowcount@"></else>
        </if>
        <else>
            <if @table.transition_selected_p@ eq 1><td align="center" bgcolor="#ccccff" rowspan="@table:rowcount@"></if>
            <else><td align="center" bgcolor="#dddddd" rowspan="@table:rowcount@"></else>
        </else>
	&nbsp;&nbsp;&nbsp;&nbsp;
        <if @table.transition_url@ not nil><a href="@table.transition_url@">@table.transition_name@</a></if>
        <else>@table.transition_name@</else>
        &nbsp;&nbsp;&nbsp;&nbsp;
        <if @table.transition_trigger_type@ eq "user">
            </th>
        </if>
        <else>
            <br />(@table.transition_trigger_type@)</td>
        </else>
    </if>

    <if @table.output_place_key@ not nil>
        <td><img src="../greyarrow.gif"></td>
        <if @table.output_place_selected_p@ eq 1><td align="left" bgcolor="#ccccff"></if>
	    <else><td align="left"></else>
        <if @table.output_place_url@ not nil><a href="@table.output_place_url@">@table.output_place_name@</a></if>
	    <else>@table.output_place_name@</else>
        (@table.output_place_num@)
        <if @table.output_guard_pretty@ not nil>
	    <br /><font color="red"><strong><big>[</big> <small>@table.output_guard_pretty@</small> <big>]</big></strong></font>
        </if>
        </td>
    </if>
    <else>
        <td colspan="2">&nbsp;</td>
    </else>
</tr>
</multiple>
