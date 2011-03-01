create or replace package survsimp_survey
as
    function new (
        survey_id in survsimp_surveys.survey_id%TYPE default null,
        name in survsimp_surveys.name%TYPE,
        short_name in survsimp_surveys.short_name%TYPE,
        description in survsimp_surveys.description%TYPE,
        description_html_p in survsimp_surveys.description_html_p%TYPE default 'f',
        single_response_p in survsimp_surveys.single_response_p%TYPE default 'f',
        single_editable_p in survsimp_surveys.single_editable_p%TYPE default 't',
        enabled_p in survsimp_surveys.enabled_p%TYPE default 'f',
        type in survsimp_surveys.type%TYPE default 'general',
        display_type in survsimp_surveys.display_type%TYPE default 'list',
        package_id in survsimp_surveys.package_id%TYPE,
        object_type in acs_objects.object_type%TYPE default 'survsimp_survey',
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null,
        context_id in acs_objects.context_id%TYPE default null
    ) return acs_objects.object_id%TYPE;

    procedure del (
        survey_id in survsimp_surveys.survey_id%TYPE
    );
end survsimp_survey;
/
show errors

create or replace package body survsimp_survey
as
    function new (
        survey_id in survsimp_surveys.survey_id%TYPE default null,
        name in survsimp_surveys.name%TYPE,
        short_name in survsimp_surveys.short_name%TYPE,
        description in survsimp_surveys.description%TYPE,
        description_html_p in survsimp_surveys.description_html_p%TYPE default 'f',
        single_response_p in survsimp_surveys.single_response_p%TYPE default 'f',
        single_editable_p in survsimp_surveys.single_editable_p%TYPE default 't',
        enabled_p in survsimp_surveys.enabled_p%TYPE default 'f',
        type in survsimp_surveys.type%TYPE default 'general',
        display_type in survsimp_surveys.display_type%TYPE default 'list',
        package_id in survsimp_surveys.package_id%TYPE,
        object_type in acs_objects.object_type%TYPE default 'survsimp_survey',
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null,
        context_id in acs_objects.context_id%TYPE default null
    ) return acs_objects.object_id%TYPE
    is
        v_survey_id survsimp_surveys.survey_id%TYPE;
    begin
        v_survey_id := acs_object.new (
            object_id => survey_id,
            object_type => object_type,
            creation_date => creation_date,
            creation_user => creation_user,
            creation_ip => creation_ip,
            context_id => context_id
        );
        insert into survsimp_surveys
            (survey_id, name, short_name, description, description_html_p,
            single_response_p, single_editable_p, enabled_p, type, display_type, package_id)
            values
            (v_survey_id, new.name, new.short_name, new.description, new.description_html_p,
            new.single_response_p, new.single_editable_p, new.enabled_p, new.type, new.display_type, new.package_id);

        return v_survey_id;
    end new;

    procedure del (
        survey_id survsimp_surveys.survey_id%TYPE
    )
    is
    begin
        delete from survsimp_surveys
            where survey_id = survsimp_survey.del.survey_id;
        acs_object.del(survey_id);
    end del;
end survsimp_survey;
/
show errors

--
-- constructor for a survsimp_question
--
create or replace package survsimp_question
as
    function new (
        question_id in survsimp_questions.question_id%TYPE default null,
        survey_id in survsimp_questions.survey_id%TYPE default null,
        sort_key in survsimp_questions.sort_key%TYPE default null,
        question_text in survsimp_questions.question_text%TYPE default null,
        abstract_data_type in survsimp_questions.abstract_data_type%TYPE default null,
        required_p in survsimp_questions.required_p%TYPE default 't',
        active_p in survsimp_questions.active_p%TYPE default 't',
        presentation_type in survsimp_questions.presentation_type%TYPE default null,
        presentation_options in survsimp_questions.presentation_options%TYPE default null,
        presentation_alignment in survsimp_questions.presentation_alignment%TYPE default 'below',
        object_type in acs_objects.object_type%TYPE default 'survsimp_question',
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null,
        context_id in acs_objects.context_id%TYPE default null
    ) return acs_objects.object_id%TYPE;

    procedure del (
        question_id in survsimp_questions.question_id%TYPE
    );
end survsimp_question;
/
show errors

create or replace package body survsimp_question
as
    function new (
        question_id in survsimp_questions.question_id%TYPE default null,
        survey_id in survsimp_questions.survey_id%TYPE default null,
        sort_key in survsimp_questions.sort_key%TYPE default null,
        question_text in survsimp_questions.question_text%TYPE default null,
        abstract_data_type in survsimp_questions.abstract_data_type%TYPE default null,
        required_p in survsimp_questions.required_p%TYPE default 't',
        active_p in survsimp_questions.active_p%TYPE default 't',
        presentation_type in survsimp_questions.presentation_type%TYPE default null,
        presentation_options in survsimp_questions.presentation_options%TYPE default null,
        presentation_alignment in survsimp_questions.presentation_alignment%TYPE default 'below',
        object_type in acs_objects.object_type%TYPE default 'survsimp_question',
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null,
        context_id in acs_objects.context_id%TYPE default null
    ) return acs_objects.object_id%TYPE
    is
        v_question_id survsimp_questions.question_id%TYPE;
    begin
        v_question_id := acs_object.new (
            object_id => question_id,
            object_type => object_type,
            creation_date => creation_date,
            creation_user => creation_user,
            creation_ip => creation_ip,
            context_id => survey_id
        );
        insert into survsimp_questions
            (question_id, survey_id, sort_key, question_text, abstract_data_type,
            required_p, active_p, presentation_type, presentation_options,
            presentation_alignment)
            values
            (v_question_id, new.survey_id, new.sort_key, new.question_text, new.abstract_data_type,
            new.required_p, new.active_p, new.presentation_type, new.presentation_options,
            new.presentation_alignment);
        return v_question_id;
    end new;

    procedure del (
        question_id in survsimp_questions.question_id%TYPE
    )
    is
    begin
        delete from survsimp_questions
            where question_id = survsimp_question.del.question_id;
        acs_object.del(question_id);
    end del;
end survsimp_question;
/
show errors

--
-- constructor for a survsimp_response
--
create or replace package survsimp_response
as
    function new (
        response_id in survsimp_responses.response_id %TYPE default null,
        survey_id in survsimp_responses.survey_id%TYPE default null,
        title in survsimp_responses.title%TYPE default null,
        notify_on_comment_p in survsimp_responses.notify_on_comment_p%TYPE default 'f',
        object_type in acs_objects.object_type%TYPE default 'survsimp_response',
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null,
        context_id in acs_objects.context_id%TYPE default null
    ) return acs_objects.object_id%TYPE;

    procedure del (
        response_id in survsimp_responses.response_id%TYPE
    );
end survsimp_response;
/
show errors

create or replace package body survsimp_response
as
    function new (
        response_id in survsimp_responses.response_id %TYPE default null,
        survey_id in survsimp_responses.survey_id%TYPE default null,
        title in survsimp_responses.title%TYPE default null,
        notify_on_comment_p in survsimp_responses.notify_on_comment_p%TYPE default 'f',
        object_type in acs_objects.object_type%TYPE default 'survsimp_response',
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null,
        context_id in acs_objects.context_id%TYPE default null
    ) return acs_objects.object_id%TYPE
    is
        v_response_id survsimp_responses.response_id%TYPE;
    begin
        v_response_id := acs_object.new (
            object_id => response_id,
            object_type => object_type,
            creation_date => creation_date,
            creation_user => creation_user,
            creation_ip => creation_ip,
            context_id => context_id
        );
        insert into survsimp_responses (response_id, survey_id, title, notify_on_comment_p)
            values
            (v_response_id, new.survey_id, new.title, new.notify_on_comment_p);
        return v_response_id;
    end new;

    procedure del (
        response_id in survsimp_responses.response_id%TYPE
    )
    is
    begin
        delete from survsimp_responses
            where response_id = survsimp_response.del.response_id;
        acs_object.del(response_id);
    end del;
end survsimp_response;
/
show errors
