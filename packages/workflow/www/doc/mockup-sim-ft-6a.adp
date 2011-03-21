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
        The task is available only in these states.
      </div>
    </td>
    </tr>
    <tr class="form-element">
      <td class="form-label">Other Preconditions
      </td>
      <td class="form-widget">
              <select>
                <option selected></option>
                <option>Random, 2 outcomes</option>
                <option>Random, 3 outcomes</option>
                <option>contains(input string, test string)</option>
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
        This task executes 
            </td>
            <td class="form-widget">
              <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                <input type="radio"><span style="color:blue">Instantaneously when enabled</span></input><br/>
                <input type="radio" checked><span style="color:green">Conditional</span></input><br/>
                <input type="radio"><span style="color:red">Child Workflow</span></input>
              </font>
              <div class="form-help-text">
                <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                  What happens when this task is executed?
                </div>
            </td>
          </tr>
          <tr class="form-element">
            <td class="form-label">
              Timer
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
                <input type="radio"><span style="color:blue">Automatic</span></input><br/>
                <input type="radio" checked><span style="color:green">Conditional</span></input><br/>
                <input type="radio"><span style="color:red">Child Workflow</span></input>
              </font>
              <div class="form-help-text">
                <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                  What happens when this task is executed?
                </div>
            </td>
          </tr>
          <tr class="form-element">
            <td class="form-label" style="background-color:lightgreen">
              Assigned Role
            </td>
            <td class="form-widget">
              <select>
                <option>Asker</option>
                <option selected>Giver</option>
                </select>
              <div class="form-help-text">
                <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
                The task is assigned to this role.
              </div>
            </td>
          </tr>
          <tr class="form-element">
            <td class="form-label" style="background-color:lightgreen">
              Conditional function
            </td>
            <td class="form-widget">
              <select>
                <option>Random, 2 outcomes</option>
                <option>Random, 3 outcomes</option>
                <option selected>contains(input string, test string)</option>
                </select>
              <div class="form-help-text">
                <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
                Execute this function to determine the next state of "Elementary Private Law Template" 
              </div>
            </td>
          </tr>
          <tr class="form-element">
            <td class="form-label" style="background-color:lightgreen">
              Input
            </td>
            <td class="form-widget">
              <select>
                <option>$foo</option>
                <option>$bar</option>
                <option selected">$baz</option>
                </select>
              <div class="form-help-text">
                <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
                "Parse Input for value" requires an input value
              </div>
            </td>
          </tr>
          <tr class="form-element">
            <td class="form-label" style="background-color:lightgreen">
              Test String
            </td>
            <td class="form-widget">
              <input type="text" size="20" value="deposition"></input>
              <div class="form-help-text">
                <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
                "Parse Input for value" requires a test string
              </div>
            </td>
          </tr>
          <tr class="form-element">
                  <td class="form-label" style="background-color:lightgreen">
                    Condition True
               </td>
                  <td class="form-widget">
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
              <select>
                <option>No Change</option>
                <option>Inactive</option>
                <option>Active</option>
                <option>Complete</option>
                </select>
                </font>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                    If Input String contains Test String, set "Prepare Report for Basic Legal Case" to true
                </div>
            </td>
          </tr>
          <tr class="form-element">
                  <td class="form-label" style="background-color:lightgreen">
                    Condition False
               </td>
                  <td class="form-widget">
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
              <select>
                <option>No Change</option>
                <option>Inactive</option>
                <option>Active</option>
                <option>Complete</option>
                </select>
                </font>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                    If Input String does not contain Test String, set "Prepare Report for Basic Legal Case" to true
                </div>
            </td>
          </tr>
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