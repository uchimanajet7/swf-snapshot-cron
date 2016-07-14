require_relative 'snapshot_cron_utils'
require_relative 'snapshot_cron_activity'
require_relative 'snapshot_cron_workflow'

workflow_input = "Amazon SWF"
SnapshotCronUtils.new.workflow_client(SnapshotCronWorkflow).start_execution.start_execution(
    workflow_input, {workflow_name: 'run_snapshot'})