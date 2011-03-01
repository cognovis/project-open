<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>
  
  <table cellpadding=3 cellspacing=1 border=0>
    <tr class="form-element">
    <td rowspan="2">
    Enabled
    </td>
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
    <td rowspan="3" style="border-top: 1px solid black; border-bottom: 1px solid black" >
    Trigger
    </td>
                  <td class="form-label">
                Mode
               </td>
                  <td class="form-widget">
              <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                <input type="radio">Trigger instantly</input><br/>
                <input type="radio" checked><span style="color:green">Wait for a trigger</span></input><br/>
                <input type="radio"><span style="color:red">Start another workflow</span></input>
                </font>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                </div>
            </td>
          </tr>
          <tr class="form-element">
                  <td class="form-label">
                Duration
               </td>
                  <td class="form-widget">
              <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                <input type="radio" checked>No time limit</input><br/>
                <input type="radio">Trigger after <input type="text" name="timeout" size="10" /></input></input><br/>
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                  Duration is of the form '1 hour' or '1 day' etc
                  
                  </div>
                                  </font>
            </td>
          </tr>
          <tr class="form-element">
            <td class="form-label" style="background-color:lightgreen">
              Assigned Role
            </td>
            <td class="form-widget">
 <table class="list" cellpadding="3" cellspacing="1">

  
      <tr class="list-header">

        
          <th class="list">
            
              
            
          </th>
        
          <th class="list">
            
              
            
          </th>
        
      </tr>
    
    
                <tr class="list-odd">
              
    
                <td class="list">
                  Asking for Information
                </td>

              
                <td class="list">
                  
              <select>
                <option selected></option>
                <option>Asker</option>
                <option>Giver</option>
                </select>

            
                </td>
              
            </tr>
          
        
                <tr class="list-even">
              
    
                <td class="list">
                  Waiting for Response
                </td>
              
                <td class="list">

                  
              <select>
                <option></option>
                <option>Asker</option>
                <option selected>Giver</option>
                </select>
            
                </td>
              
            </tr>
          
        
                <tr class="list-odd">
              
    
                <td class="list">
                  Completed
                </td>
              
                <td class="list">
                  
              <select>
                <option selected></option>
                <option>Asker</option>
                <option>Giver</option>
                </select>
                </td>
              
            </tr>
          
        

  </table>
              <div class="form-help-text">
                <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0"/>
                The task is assigned to this role.
              </div>
            </td>
          </tr>
          <tr class="form-element">
    <td rowspan="2">
    Outcome
    </td>
            <td class="form-label">
              New State
            </td>
            <td class="form-widget">
            <input type="radio" name="outcome">Don't change state</input><br>
            <input type="radio" name="outcome"><b>Asking for Information</b></input<br/>
            <input type="radio" name="outcome"><b>Waiting for Response</b></input><br/>
            <input type="radio" name="outcome" checked><b>Completed</b></input><br/>
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