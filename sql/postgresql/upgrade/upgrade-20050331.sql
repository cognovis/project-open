alter table flexbase_layout_pages drop constraint flexbase_layout_type_ck;

alter table flexbase_layout_pages add constraint flexbase_layout_type_ck 
check (layout_type in ( 'absolute','relative','adp' ));
