<master src="../../master">
<property name="title">Form Widget Wizard</property>

<h2>Form Widget Wizard</h2>
<multiple name="wizard">

  <if @wizard.id@ ne @wizard:current_id@>
    <a href="@wizard.link@">@wizard.rownum@. @wizard.label@</a>  
  </if>
  <else>
    @wizard.rownum@. @wizard.label@
  </else>  

  <if @wizard.rownum@ lt @wizard:rowcount@> &sect; </if>
</multiple>

<hr>
<include src="@wizard:current_url;noquote@">

