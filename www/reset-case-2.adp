<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">rfc</property>

<if @button_cancel@ ne "">
<h1>Abgebrochen</h1>
Es wurde keine Aktion durchgef&uuml;hrt.
</if>

<if @button_confirm@ ne "">
<h1>Aktion durchgef&uuml;hrt</h1>
Die Aktion '@action_pretty;noquote@' wurde erfolgreich durchgef&uuml;hrt.
</if>

<ul>
<li><a href="@return_url;noquote@">Zur&uuml;ck zur RFC Sicht</a>.
</ul>
