<if @notes:rowcount@ ne 0>

<table cellspacing="1" cellpadding="3">
  <tr class="rowtitle">
    <th>Type</th>
    <th>Note</th>
  </tr>
  <multiple name="notes">
    <if @notes.rownum@ odd><tr class="roweven"></if>
    <else><tr class="rowodd"></else>
	<td>@notes.note_type@</td>
	<td>@notes.note@</td>
    </tr>
  </multiple>
</table>
</if>

<if @write@>
<li><a href="@new_note_url;noquote@">Create a new Note</a>
</if>
