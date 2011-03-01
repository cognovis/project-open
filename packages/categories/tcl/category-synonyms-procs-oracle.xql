<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="category_synonym::add.insert_synonym">
      <querytext>
		begin
		:1 := category_synonym.new (
					    synonym_id   => :synonym_id,
					    name         => :name,
					    locale       => :locale,
					    category_id  => :category_id
					   );
		end;
      </querytext>
</fullquery>

<fullquery name="category_synonym::edit.update_synonym">
      <querytext>
		begin
		:1 := category_synonym.edit (
					     synonym_id   => :synonym_id,
					     name         => :name,
					     locale       => :locale
					    );
		end;
      </querytext>
</fullquery>

<fullquery name="category_synonym::delete.delete_synonym">
      <querytext>
		begin
		category_synonym.del (
				      synonym_id   => :synonym_id
				     );
		end;
      </querytext>
</fullquery>

<fullquery name="category_synonym::search.new_search">
      <querytext>
		begin
		:1 := category_synonym.search (
					           search_text  => :search_text,
					           locale       => :locale
					          );
		end;
      </querytext>
</fullquery>

<fullquery name="category_synonym::search_sweeper.delete_old_searches">
      <querytext>
		delete from category_search
		where last_queried < sysdate - 1
      </querytext>
</fullquery>

</queryset>
