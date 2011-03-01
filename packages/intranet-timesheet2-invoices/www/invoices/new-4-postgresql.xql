<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-timesheet2-invoices/www/invoices/new-4-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-22 -->
<!-- @arch-tag 54c65a18-8987-418f-aa60-0e924fa0a21e -->
<!-- @cvs-id $Id: new-4-postgresql.xql,v 1.2 2008/07/30 14:52:37 cambridge Exp $ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  

  <fullquery name="create_invoice">
    <querytext>

      select im_timesheet_invoice__new (
                :invoice_id,
                'im_timesheet_invoice',
                now(),
                :user_id,
                '[ad_conn peeraddr]',
                null,
                :invoice_nr,
                :customer_id,
                :provider_id,
                null,
                :invoice_date,
                :invoice_currency,
                :template_id,
                :cost_status_id,
                :cost_type_id,
                :payment_method_id,
                :payment_days,
                '0',
                :vat,
                :tax,
                null
            );

    </querytext>
  </fullquery>


  <fullquery name="insert_acs_rels">
    <querytext>

      select acs_rel__new(
               null,
               'relationship',
               :project_id,
               :invoice_id,
               null,
               null,
               null
      );

    </querytext>
  </fullquery>

</queryset>
