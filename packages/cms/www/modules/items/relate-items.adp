<master src="../../master">
<property name="title">@page_title;noquote@</property>

<h2>@page_title@ (Step 1)</h2>
<a href="index?item_id=@item_id@">@item_title@</a>

<hr>

<if @no_items_on_clipboard@ eq "t">
  <p>No items are currently available for relating.  Please mark
     your choices and return to this form.</p>
</if>
<else>
  <if @no_valid_items@ eq "t">
    <p>None of the marked items may be related to "@item_title@"</p>
  </if>
  <else>
  <formtemplate id=rel_form style=grid cols=8
     headers="Check Title Type Tag Order" title="Choose items to relate"></formtemplate>
  </else>
</else>