<table align=center cellspacing=0 cellpadding=1 border=0>
<tr bgcolor=#999999><td>
<table width=\"100%\" cellspacing=0 cellpadding=0 border=0>
<tr bgcolor=#eeeeee>
<td>

<table width=\"100%\" cellspacing=0 cellpadding=2 border=0>
<tr bgcolor=#eeeeee>
<td>&nbsp;</td>
<td>Simple Process Wizard:</td>
<td>&nbsp;</td>
<multiple name="steps">
    <if @steps.rownum@ ne 1><td><img src="slim-right-arrow" height=32 width=32></td></if>

    <if @steps.status@ eq "completed">
	<td><if @no_links@ eq 0><a href="@steps.url@"></if><b>@steps.name@</b><if @no_links@ eq 0></a></if></td>
    </if>

    <if @steps.status@ eq "current">
	<td bgcolor=#9999f6><b>@steps.name@</b></td>
    </if>

    <if @steps.status@ eq "future">
	<td><font color=#999999><b>@steps.name@</b></font></td>
    </if>
</multiple>

<td>&nbsp;</td>
</tr>
</table>

</td></tr>
</table>
</td></tr>
</table>
