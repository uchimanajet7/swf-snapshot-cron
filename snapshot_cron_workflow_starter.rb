require_relative 'snapshot_cron_utils'
require_relative 'snapshot_cron_activity'
require_relative 'snapshot_cron_workflow'

SnapshotCronUtils.new.workflow_client(SnapshotCronWorkflow).start_execution
