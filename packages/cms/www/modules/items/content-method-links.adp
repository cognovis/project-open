
<if @content_methods_ds:rowcount@ gt 0>

  [

  <multiple name="content_methods_ds">
    <a href="@target_url@?item_id=@item_id@&content_type=@content_type@&content_method=@content_methods_ds.method@">@content_methods_ds.label@</a>
    <if @content_methods_ds.rownum@ lt @content_method_count@> | </if>

  </multiple>

  ]

</if>