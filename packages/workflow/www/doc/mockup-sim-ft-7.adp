<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
  
  <table cellpadding=3 cellspacing=1 border=0>
    <tr class="form-element">
      <td class="form-label">Enabled in state
      </td>
      <td class="form-widget">
      <listtemplate    name="states"></listtemplate>
      <div class="form-help-text">
        <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
        Initialize is a special task.  It is automatically run when a
    workflow is initialized. it (TODO: can, can't) be run in other states."
      </div>
    </td>
    </tr>
    <tr class="form-element">
      <td class="form-label">Other Preconditions
      </td>
      <td class="form-widget">
              <select>
                <option>Random, 2 outcomes</option>
                <option>Random, 3 outcomes</option>
                <option selected>contains(input string, test string)</option>
                </select>
                <input type="submit" value="Add Condition">
        <div class="form-help-text">
          <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
          All of these conditions must also be true for the task to be enabled.
        </div>
      </td>
    </tr>
    <tr class="form-element">
                  <td class="form-label">
                Time Limit
               </td>
                  <td class="form-widget">
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                     <input type="text" name="timeout" size="10" /> 
                </font>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                  The action will automatically execute its Transformation this long after it is enabled. Leave blank to never timeout
                </div>
            </td>
          </tr>
          <tr class="form-element">
            <td class="form-label">
              Transformation
            </td>
            <td class="form-widget">
              <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                <input type="radio" checked><span style="color:blue">Automatic</span></input><br/>
                <input type="radio"><span style="color:green">Conditional</span></input><br/>
                <input type="radio"><span style="color:red">Child Workflow</span></input>
              </font>
              <div class="form-help-text">
                <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                  What happens when this task is executed?  TODO - how
    do we make a "conditional conditional" - ie, how do we indicate
    that conditional action is available if role is uncast?  "default transformation?"
                </div>
            </td>
          </tr>
          <tr class="form-element">
            <td class="form-label" style="background-color:lightblue">
              Next State
            </td>
            <td class="form-widget">
              <select>
                <option>Active</option>
                <option>Complete</option>
                </select>
              <div class="form-help-text">
                <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
                Activating this task changes "Elementary Private Law Template" to this state 
              </div>
            </td>

          <tr class="form-element">
            <td class="form-label">
              Additional Effects
            </td>
            <td class="form-widget">
              <div class="form-help-text">
                <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
                When this task is completed, these things also happen
              </div>
            </td>
          </tr>

</table>