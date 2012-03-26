-- upgrade-4.0.2.0.5-4.0.2.0.6.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-4.0.2.0.5-4.0.2.0.6.sql','');


-- New Widget for queues
SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'ticket_queues', 'Ticket Queues', 'Ticket Queues',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
		select	g.group_id, g.group_name
		from	groups g,
			acs_objects o
		where	o.object_type = ''im_ticket_queue'' and
			g.group_id = o.object_id
		order by lower(g.group_name)
	}}}'
);


SELECT im_component_plugin__new (
	null,				-- plugin_id
	'im_component_plugin',		-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Customer Information AJAX',	-- plugin_name - shown in menu
	'intranet-helpdesk',		-- package_name
	'new_right',			-- location
	'/intranet-helpdesk/new',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'set a "<div id=customer_contact_div></div>"'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Customer Information AJAX' and package_name = 'intranet-helpdesk'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);





SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'customer_contact_select_ajax', 'Customer Contact Select AJAX', 'Customer Contact Select AJAX',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {
		select	p.project_id,
			p.project_name
		from 	im_projects p
		where	p.project_type_id = 2502 and
			p.project_status_id in (select * from im_sub_categories(76))
		order by lower(project_name) 
	}}

	after_html {
		<script type="text/javascript">
		function customerContactSelectOnChange() {
		    var xmlHttp1;
		    try { xmlHttp1=new XMLHttpRequest();	// Firefox, Opera 8.0+, Safari
		    } catch (e) {
			try { xmlHttp1=new ActiveXObject("Msxml2.XMLHTTP");	// Internet Explorer
			} catch (e) {
			    try { xmlHttp1=new ActiveXObject("Microsoft.XMLHTTP");
			    } catch (e) {
				alert("Your browser does not support AJAX!");
				return false;
			    }
			}
		    }
		    xmlHttp1.onreadystatechange = function() {
			if(xmlHttp1.readyState==4) {
			    var divElement = document.getElementById(''customer_contact_div'');
				divElement.innerHTML = this.responseText;
			}
		    }
		    var customer_id = document.helpdesk_ticket.ticket_customer_contact_id.value;
		    xmlHttp1.open("GET","/intranet/components/ajax-component-value?plugin_name=Customer%20Info&package_key=intranet-helpdesk&ticket_customer_contact_id=" + customer_id,true);
		    xmlHttp1.send(null);
		}
		window.onload = function() {
		    var dropdown = document.helpdesk_ticket.ticket_customer_contact_id;
		    dropdown.onchange = customerContactSelectOnChange;

		    var divElement = document.getElementById(''customer_contact_div'');
		    if (divElement != null){
			var div = document.helpdesk_ticket.ticket_customer_contact_id;
			div.onchange = customerContactSelectOnChange;        
			if (div.value != null) { customerContactSelectOnChange() }
		}
		}
		</script>
	}
}'
);


-- Creation Date
create or replace function inline_0 ()
returns integer as '
declare
        v_count integer;
begin
        select  count(*) into v_count from user_tab_columns
        where   lower(table_name) = ''im_tickets'' and
                lower(column_name) = ''ticket_component_id'';
        IF 0 != v_count THEN return 0; END IF;

        alter table im_tickets add
        ticket_component_id                     integer
                                        constraint im_ticket_component_fk
                                        references im_conf_items;
        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

