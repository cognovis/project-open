<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="create_response">      
      <querytext>
	select survsimp_response__new (
		:response_id,
		:survey_id,		
		null,
		'f',
		:user_id,
		:creation_ip,
		:survey_id
	    )
      </querytext>
</fullquery>

<fullquery name="survsimp_question_response_text_insert">
      <querytext>

      insert into survsimp_question_responses
      (response_id, question_id, clob_answer)
      values 
      (:response_id, :question_id, :clob_answer)

      </querytext>
</fullquery>

<fullquery name="create_item">
      <querytext>

      select content_item__new (
	   varchar :name,
	   null,
	   null,
	   null,
	   now(),
	   :user_id,
	   null,
           :creation_ip,
	   'content_item',
	   'content_revision',
	   null,
	   null,
	   'text/plain',
	   null,
	   null,
	   'file'
           )

      </querytext>
</fullquery>


<fullquery name="create_rel">
      <querytext>

      select acs_rel__new (
	  null,
          'user_blob_response_rel',
          :user_id,
          :item_id,
	  null,
	  null,
	  null
      )

      </querytext>
</fullquery>


<fullquery name="create_revision">
      <querytext>

      declare
	  v_revision_id		integer;
      begin
          v_revision_id := content_revision__new (
          'A Blob Response',
	  null,
	  now(),
          :guessed_file_type,
	  null,
          'not_important',
          :item_id,
	  null,
          now(),
          :user_id,
          :creation_ip
          );

          update cr_items
          set live_revision = v_revision_id
          where item_id = :item_id;

	  return v_revision_id;

      end;

      </querytext>
</fullquery>


<fullquery name="update_response">
      <querytext>

      update cr_revisions
      set content = '[cr_create_content_file $item_id $revision_id $tmp_filename]'
      where revision_id = :revision_id

      </querytext>
</fullquery>

 
</queryset>
