<div class="standard-form">
  <multiple name=elements>

    <if @elements.section@ not nil>
      <if @elements.section@ eq "endsection">
        </fieldset>
      </if>
      <else>
        <fieldset class="standard-form-section"><legend class="standard-form-section-legend">@elements.section@</legend>
      </else>
    </if>

    <group column="section">
      <if @elements.widget@ eq "hidden">
        <div><noparse><formwidget id=@elements.id@></noparse></div>
      </if>

      <else>

        <if @elements.widget@ eq "submit">
          <if @elements.section@ not nil>
      </fieldset>
          </if>
          <div class="submit-buttons-row">
	    <span class="form-label">&nbsp;</span>
              <group column="widget">
                <noparse><formwidget id="@elements.id@"></noparse>
              </group>
          </div>
        </if>
        <else>

<if @elements.help@ not nil> <div class="@elements.help@"> </if>

              <if @elements.label@ not nil>
                  <if @elements.optional@ nil and @elements.mode@ ne "view" and @elements.widget@ ne "inform">
          			<div class="required-form-row">

                        <if @elements.widget@ in radio checkbox>
                                       <label class="form-label">@elements.label;noquote@: <span>*</span></label>
                        </if>
                        <else>
                                       <label for="@elements.id@" class="form-label">@elements.label;noquote@: <span>*</span></label>
                        </else>


                  </if>
                  <else>

          <div class="standard-form-row">
                        <if @elements.widget@ in radio checkbox>
                                       <label class="form-label">@elements.label;noquote@:</label>
                        </if>
                        <else>
                                       <label for="@elements.id@" class="form-label">@elements.label;noquote@:</label>
                        </else>

                  </else>

               </if>
               <else>

          <div class="standard-form-row">
            <span class="form-label">&nbsp;</span>
               </else>

               <if @elements.multiple@ nil and @elements.widget@ in radio checkbox>
                <noparse>
                    <formgroup id="@elements.id@">
                        \@formgroup.widget;noquote@
      					  <if \@formgroup.label@ not nil>
      					    <label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option@">
                              \@formgroup.label;noquote@
                            </label>
                          </if>
                    </formgroup>
                </noparse>
               </if>
               <elseif @elements.widget@ in radio checkbox>
                <noparse>
                    <formgroup id="@elements.id@">
                        <div class="standard-form-text">
      					  <if \@formgroup.label@ not nil>
      					    <label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option@">
                              \@formgroup.label;noquote@:
                            </label>
                          </if>
                          \@formgroup.widget;noquote@ &nbsp;&nbsp;
                        </div>
                    </formgroup>
                </noparse>
               </elseif>

               <else>

                  <noparse>
                    <formwidget id="@elements.id@">
                  </noparse>
               </else>
                   </div>

              <noparse>
                <formerror id="@elements.id@">
                <div class="standard-form-row">
                  <span class="form-label"> </span>
                  <div class="standard-form-error" style="color:#ff0000">
                    \@formerror.@elements.id@;noquote\@
                  </div>
                    </div>
                </formerror>
              </noparse>

               <if @elements.help_text@ not nil and @elements.mode@ ne "view">
               <div class="standard-form-row">
                 <span class="form-label"> </span>
                 <div class="standard-form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
                  <noparse><formhelp id="@elements.id@"></noparse>
                </div>
              </div>
          </if>

<if @elements.help@ not nil> </div> </if>


        </else>
      </else>
    </group>
  </multiple>
</div>

<multiple name="elements">
    <if @elements.optional@ nil and @elements.mode@ ne "display" and @elements.widget@ ne "inform" and @elements.widget@ ne "hidden" and @elements.widget@ ne "submit">
       <div class="standard-display-item" style="color:#ff0000">* #acs-templating.required# </div><% break %>
    </if>
</multiple>

