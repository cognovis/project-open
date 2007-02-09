<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">rfc</property>

<h1>Best&auml;tigung @action_pretty;noquote@</h1>

Wollen Sie diesen RFC wirklich @action_pretty;noquote@?
<p>

<form action=reset-case-2 method=POST>
<%= [export_form_vars return_url project_id task_id place_key action_pretty] %>
<input type=submit name=button_cancel value="Abbrechen">
<input type=submit name=button_confirm value="RFC @action_pretty;noquote@">
</form>
