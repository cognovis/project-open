<!-- Form elements -->
  <multiple name=elements>

    <if @elements.section@ not nil>
      <span class="form-section">@elements.section@</span>
    </if>

    <group column="section">
      <if @elements.widget@ eq "hidden"> 
        <noparse><formwidget id=@elements.id@></noparse>
      </if>
  
      <else>

        <if @elements.widget@ eq "submit">
            <span class="form-element">
              <group column="widget">
                <noparse><formwidget id="@elements.id@"></noparse>
              </group>
            </span>
        </if>

        <else>
            <if @elements.label@ not nil>
              <noparse>
                <if \@formerror.@elements.id@\@ not nil>
                  <span class="form-label-error">
                  </if>
                <else>
                  <span class="form-label">
                  </else>
              </noparse>
                    @elements.label;noquote@
                <if @form_properties.show_required_p@ true>
                <if @elements.optional@ nil and @elements.mode@ ne "display" and @elements.widget@ ne "inform" and @elements.widget@ ne "select"><span class="form-required-mark">*</span></if>


                </if>
              </span>
            </if>
            <else>
            </else>

              <noparse>
                <formerror id="@elements.id@">
                    <div style="color: red; display: inline; background-color: #FCC; padding: 5px;">
                    <strong>\@formerror.@elements.id@;noquote\@:</strong>
                </formerror>
              </noparse>

              <noparse>
                <if \@formerror.@elements.id@\@ not nil>
                  <span class="form-widget-error">
              </if>
                <else>
                  <span class="form-widget">                  
                </else>
              </noparse>

              <if @elements.widget@ in radio checkbox>
                <noparse>
                  <table>
                    <formgroup id="@elements.id@">
                      <tr><td>
                        \@formgroup.widget;noquote@
                            <label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option@">
                              \@formgroup.label@
                            </label>

                      </td></tr>
                    </formgroup>
                  </table>
                </noparse>
              </if>

              <else>
                  <noparse>
                    <formwidget id="@elements.id@">
                  </noparse>
              </else>

              <noparse>
                <formerror id="@elements.id@">
                    </div>
                </formerror>
              </noparse>

              <if @elements.help_text@ not nil>
                <p style="margin-top: 4px; margin-bottom: 2px;">
                    <noparse>
                      <i><formhelp id="@elements.id@"></i>
                    </noparse>
                </p>
              </if>

              </span>

        </else>
      </else>
    </group>
  </multiple>
 
