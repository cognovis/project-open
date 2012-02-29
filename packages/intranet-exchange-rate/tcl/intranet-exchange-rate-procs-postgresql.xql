<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-exchange-rates/tcl/intranet-exchange-rate-procs-postgresql.xql -->
<!-- @author  (frank.bergmann@project-open.com) -->
<!-- @creation-date 2005-06-09 -->
<!-- @arch-tag 0cbec04f-a982-45e4-88b0-c5933aaa9b0b -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="im_exchange_rate_helper.exchange_rate">
    <querytext>

      select im_exchange_rate (:day, :from_cur, :to_cur);

    </querytext>
  </fullquery>
</queryset>
