<if @versions_p@ true>
  <div class="bt_navbar" style="clear: right; float: right; padding: 4px; background-color: #41329c; text-align: center;">

    <if @user_id@ ne 0>
      Your version: <a href="@user_version_url@" class="bt_navbar" style="font-size: 100%;">@user_version_name@</a>
      <if @user_version_id@ ne @current_version_id@>
        | Current: @current_version_name@
      </if>
      <else>
        (current)
      </else>
    </if>

    <else>
      Current version: @current_version_name@
    </else>

  </div>
</if>

