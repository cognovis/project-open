<if @conf_items:rowcount@ ne 0>
	<table cellspacing="1" cellpadding="3">
	  <tr class="rowtitle">
	    <th>Type</th>
	    <th>Conf Item</th>
	  </tr>
	  <multiple name="conf_items">
	    <if @conf_items.rownum@ odd><tr class="roweven"></if>
	    <else><tr class="rowodd"></else>
		<td>@conf_items.conf_item_name@</td>
		<td>@conf_items.conf_item_type@</td>
	    </tr>
	  </multiple>
	</table>
</if>

<formtemplate id=form></formtemplate>

