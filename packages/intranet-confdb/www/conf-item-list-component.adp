<if @conf_items:rowcount@ ne 0>
	<table cellspacing="1" cellpadding="3" class="table_component">
	<thead>
	  <tr class="rowtitle">
	    <th><%= [lang::message::lookup "" intranet-confdb.Conf_Item "Conf Item"] %></th>
	    <th><%= [lang::message::lookup "" intranet-confdb.Conf_Item_Type "Type"] %></th>
	  </tr>
	</thead>
	<tbody>
	  <multiple name="conf_items">
	    <if @conf_items.rownum@ odd><tr class="roweven"></if>
	    <else><tr class="rowodd"></else>
		<td><a href="@conf_items.conf_item_url@">@conf_items.conf_item_name@</a></td>
		<td><a href="@conf_items.conf_item_url@">@conf_items.conf_item_type@</a></td>
	    </tr>
	  </multiple>
	</tbody>
	</table>
</if>

<br>
<formtemplate id=@form_id@></formtemplate>

