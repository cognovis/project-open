function <%=$form_id%>_update_target_select() {

    // console.log("Start 'update_target_select'");
    var xmlHttp1;
    // get value from first request 
    try {
	// Firefox, Opera 8.0+, Safari
	xmlHttp1=new XMLHttpRequest();
    }
    catch (e) {
	// Internet Explorer
	try {
	    xmlHttp1=new ActiveXObject("Msxml2.XMLHTTP");
	}
	catch (e) {
	    try {
		xmlHttp1=new ActiveXObject("Microsoft.XMLHTTP");
	    }
	    catch (e) {
		alert("Your browser does not support AJAX!");
		return false;
	    }
	}
    }

    xmlHttp1.onreadystatechange = function() {
	// console.log("now in 'onreadystatechange', xmlHttp1.readyState=", xmlHttp1.readyState);	
	if(xmlHttp1.readyState==4) {

	    // Removing acual options
	    for (i = oForm.<%=$target_form_element_name%>.options.length-1; i >= 0; i--) { 
		oForm.<%=$target_form_element_name%>.remove(i); 
	    }

	    // Get response  	
	    var xml_options = xmlHttp1.responseText;

	    // Setting new options "Target" (XML) 
	    $(xml_options).find('select_item').each(function(){
		var title = $(this).find('title').text();
		var values = $(this).find('value').text();
		 $("#<%=$form_id%> select[name=<%=$target_form_element_name%>]").append("<option value='"+ $.trim(values) +"'>"+ title +"</option>");
	    });

	    // Setting pre-select 	    
	    var target_form_element_value = $(xml_options).find('target_form_element_value').text();
	    // console.log("Found pre-set value target:", target_form_element_value);
	    $("#<%=$form_id%> select[name=<%=$target_form_element_name%>]").val(target_form_element_value);

	    // todo: setting new option (JSON)

	    // Deprecated: 
	    // var opts1 = res1.split("|");
	    // for (i=0; i < opts1.length; i = i+2) {
	    //	var newOpt = new Option(opts1[i+1], opts1[i], false, true);
	    //	newOpt.value = $.trim(newOpt.value);	
	    //	oForm.cost_object_category_id.options[oForm.<%=$target_form_element_name%>.options.length] = newOpt;
	    // }
	}
    }

    // Set JS var for source & target 
    var oForm = document.forms['<%=$form_id%>'];
    var <%=$source_form_element_name%>_value = oForm.elements["<%=$source_form_element_name%>"].options[oForm.elements["<%=$source_form_element_name%>"].selectedIndex].value;
    var <%=$target_form_element_name%>_value = oForm.elements["<%=$target_form_element_name%>"].options[oForm.elements["<%=$target_form_element_name%>"].selectedIndex].value;

    xmlHttp1.open(<%=$request_str%>);
    xmlHttp1.send(null);
}


jQuery().ready(function(){
	// Check if source_select has a value
	var oForm = document.forms['<%=$form_id%>'];
	var <%=$source_form_element_name%>_value = oForm.elements["<%=$source_form_element_name%>"].options[oForm.elements["<%=$source_form_element_name%>"].selectedIndex].value;
	// console.log("jQuery.ready - Found <%=$source_form_element_name%>_value:%", <%=$source_form_element_name%>_value);
	if ( <%=$source_form_element_name%>_value != null && <%=$source_form_element_name%>_value != "" ) {
		 console.log("Setting target select");
		// found value, now updating target 
		<%=$form_id%>_update_target_select();
	}

	// Create "Listener" for source element 
	console.log("Setting Listener for doc id <%=$source_form_element_name%>");
	$("#<%=$form_id%> select[name=<%=$source_form_element_name%>]").change(<%=$form_id%>_update_target_select);
});

