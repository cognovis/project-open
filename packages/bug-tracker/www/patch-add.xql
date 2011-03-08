<?xml version="1.0"?>
<queryset>

<fullquery name="patch_number_for_id">
      <querytext>
select patch_number 
        from bt_patches 
        where patch_id = :patch_id
      </querytext>
</fullquery>


</queryset>
