<master src="../../master">
<property name="title">Preview Attribute Widget</property>

<if @widget@ nil>
  <h3>You must select a widget for this attribute!</h3>
  <a href="widget-register?attribute_id=@attribute_id@">
    Select a widget</a>
</if>
<else>

  <if @outstanding_params@ eq 0>
    <h3>Preview Attribute Widget</h3>
    <formtemplate id="widget_preview" style="wizard"></formtemplate>
  </if>
  <else>
    <h3>The following widget params must have values:</h3>
    @outstanding_params_list@

    <p>
    Please <a href="@back_url@">Go Back</a> and edit widget params.

  </else>

</else>
