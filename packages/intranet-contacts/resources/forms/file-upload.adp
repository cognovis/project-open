<!-- Form elements -->
<table class="list" cellpadding="3" cellspacing="1">
        <tr class="list-header">
           <th class="list-narrow">File</th>
           <th class="list-narrow">Rename to</th>
  <multiple name=elements>

    <if @elements.section@ not nil>
        </tr>
        <tr class="list-odd">
    </if>

    <group column="section">
      <if @elements.widget@ eq "hidden"> 
        <noparse><formwidget id=@elements.id@></noparse>
      </if>
  
      <else>

        <if @elements.widget@ in text file><td class="list-narrow"></if>


        <if @elements.widget@ eq "submit">
            </tr>
            <tr>
               <td colspan="2">
              <group column="widget">
                <noparse><formwidget id="@elements.id@"></noparse>
              </group>
                </span>
               </td>
           </tr>
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
                  <br>
                  <font color="red">
                    <b>\@formerror.@elements.id@;noquote\@<b>
                  </font>
                </formerror>
              </noparse>

              <if @elements.help_text@ not nil>
                <p style="margin-top: 4px; margin-bottom: 2px;">
                    <noparse>
                      <i><formhelp id="@elements.id@"></i>
                    </noparse>
                </p>
              </if>

        </else>
      </else>
    </group>
  </multiple>
 
</table>
