<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="report_insert">
        <querytext>

	declare
	
	begin
	    v_menu_id := im_report.new (
	    	creation_user	=> :user_id,
		creation_ip	=> :user_ip,
	        report_id       => :report_id,
	        report_name     => :report_name,
	        view_id         => :view_id,
	        report_status_id => :report_status_id,
	        report_type_id  => :report_type_id,
	        description  	=> :description
	    );
	end;

        </querytext>
</fullquery>

</queryset>
