<br>
<table>
<tr>
   <td>
    <formtemplate id="aggregate" style="inline"></formtemplate>
   </td>
   <td>&nbsp;&nbsp;</td>
   <td>
   <formtemplate id="extend" style="inline"></formtemplate>
   </td>
</tr>
</table>
<br>
@message;noquote@ <br>
#intranet-contacts.aggregated_by# <b>@attr_name;noquote@</b>
<if @extend_id@ not nil>
<br>#intranet-contacts.extended_by# <b>@extend_pretty_name;noquote@</b>
</if>
<br>
<br>

<listtemplate name="contacts"></listtemplate>
<br>
<formtemplate id="save">
<input type="submit" value="Save">
</formtemplate>