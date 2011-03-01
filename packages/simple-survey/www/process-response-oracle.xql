<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="create_response">      
      <querytext>
      
	begin
	    :1 := survsimp_response.new (
		response_id => :response_id,
		survey_id => :survey_id,		
		context_id => :survey_id,
		creation_user => :user_id
	    );
	end;
    
      </querytext>
</fullquery>


<fullquery name="survsimp_question_response_text_insert">
      <querytext>

      insert into survsimp_question_responses
      (response_id, question_id, clob_answer)
      values 
      (:response_id, :question_id, empty_clob())
      returning clob_answer into :1

      </querytext>
</fullquery>


<fullquery name="create_item">
      <querytext>

       begin
           :1 := content_item.new (
           name => :name,
           creation_ip => :creation_ip
	   );
       end;

      </querytext>
</fullquery>


<fullquery name="create_rel">
      <querytext>

      begin
 	  :1 := acs_rel.new (
 	  rel_type => 'user_blob_response_rel',
 	  object_id_one => :user_id,
 	  object_id_two => :item_id);
      end;

      </querytext>
</fullquery>


<fullquery name="create_revision">
      <querytext>

      begin
	  :1 := content_revision.new (
	  title => 'A Blob Response',
	  item_id => :item_id,
	  text => 'not_important',
	  mime_type => :guessed_file_type,
	  creation_date => sysdate,
	  creation_user => :user_id,
	  creation_ip => :creation_ip
	  );

          update cr_items
          set live_revision = :1
          where item_id = :item_id;

      end;

      </querytext>
</fullquery>


<fullquery name="update_response">
      <querytext>

      update cr_revisions
      set content = empty_blob()
      where revision_id = :revision_id
      returning content into :1

      </querytext>
</fullquery>

</queryset>
