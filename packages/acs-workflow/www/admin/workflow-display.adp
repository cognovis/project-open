<if @format@ eq "html">

<h3><#Transitions Transitions#></h3>
<table cellpadding="2" cellspacing="2" border="0">
<multiple name="transitions">
    <include src="transition-display" &="workflow" transition_key="@transitions.transition_key;noquote@" selected_transition_key="@transition_key;noquote@" selected_place_key="@place_key;noquote@">
    <tr><td colspan="5">&nbsp;</td></tr>
</multiple>
</table>

<h3><#Places Places#></h3>
<table cellpadding="2" cellspacing="2" border="0">
<multiple name="places">
    <include src="place-display" &="workflow" place_key="@places.place_key;noquote@" selected_transition_key="@transition_key;noquote@" selected_place_key="@place_key;noquote@">
</multiple>
</table>

</if>
<else>
@display;noquote@
</else>

