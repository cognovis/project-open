
-- Add a new column to determine that both panels should be overwritten
alter table wf_context_task_panels
add overrides_both_panels_p char(1)
constraint wf_context_panels_ovrd_both_ck
CHECK (overrides_both_panels_p = 't'::bpchar OR overrides_both_panels_p = 'f'::bpchar)
;


