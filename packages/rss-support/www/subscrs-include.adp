<table cellpadding="2" cellspacing="1" border="0">
<tr bgcolor=e0e0e0>
 <th>Name</th>
 <th>Timeout</th>
 <th>Last Built</th>
 <th>Last Time To Build</th>
 <th>Created By</th>
 <th>Actions</th>
</tr>
<multiple name="subscrs">
<tr bgcolor=efefef><td><if @subscrs.channel_link@ eq "">@subscrs.channel_title@</if><else><a href="@subscrs.channel_link@">@subscrs.channel_title@</a></else></else></td>
    <td>@subscrs.timeout@s</td>
    <td><nobr><small>@subscrs.lastbuild_pretty@</small></nobr></td>
    <td>@subscrs.last_ttb@ seconds</td>
    <td>@subscrs.creator@</td>
    <td><a href="@rel_path@/subscr-ae?subscr_id=@subscrs.subscr_id@">edit</a> |
        <a href="@rel_path@/subscr-run?subscr_id=@subscrs.subscr_id@&return_url=@enc_url@">run</a> | 
	<a href="@rel_path@/delete?subscr_id=@subscrs.subscr_id@&return_url=@enc_url@">delete</a></td>
</tr>
</multiple>
</table>
