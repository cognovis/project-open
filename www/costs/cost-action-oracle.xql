<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-cost/www/costs/cost-action-oracle.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-22 -->
<!-- @arch-tag 339d2c48-1fa4-4e0e-83ce-a194435a1f43 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>oracle</type>
    <version>8.1.6</version>
  </rdbms>
  
  <fullquery name = "delete_cost_item">
    <querytext>
       begin
            ${otype}.del(:cost_id);
       end;
    </querytext>
  </fullquery>
</queryset>
