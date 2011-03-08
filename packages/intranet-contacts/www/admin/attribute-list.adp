<master src="/packages/intranet-contacts/lib/contacts-master" />
<br>
<if @default_names@ not nil>
    <table>
        <tr>
        <th width=15%> #intranet-contacts.Default_attributes#: </th>
	<td width=90%> @default_names@</td>
	</tr>
    </table>
    <br>
</if>

<listtemplate name="ams_options"></listtemplate>

<br>
<center><a href="search-list">#intranet-contacts.Search_List#</a></center>
<br>
&nbsp;
