<master src="../../master">
<property name="title">Set Attribute Widget Params</property>

<if @widget@ nil>
  <h3>You must select a widget for this attribute!</h3>
  <a href="widget-register?attribute_id=@attribute_id@">
    Select a widget</a>
</if>
<else>

  <h3>Set Attribute Widget Params</h3>
  <formtemplate id="widget_register" style="wizard"></formtemplate>

</else>
