require_relative 'snapshot_cron_utils'
require_relative 'snapshot_cron_activity'

class SnapshotCronWorkflow
  extend AWS::Flow::Workflows

  workflow :run_snapshot do
    {
      version: SnapshotCronUtils::WF_VERSION,
      task_list: SnapshotCronUtils::WF_TASK_LIST,
      execution_start_to_close_timeout: 3600,
    }
  end

  activity_client(:client) { { from_class: "SnapshotCronActivity" } }

  def run_snapshot()
    on_demand, spot = client.get_active_ec2_list()

    if !demand.empty? then
        demand.each{|i|
          client.stop_ec2(i)
          client.create_ami(i,true)
          client.start_ec2(i)
        }
    end

    if !spot.empty? then
        spot.each{|i|
          client.create_ami(i,false)
        }
    end
  end
end

SnapshotCronUtils.new.workflow_worker(SnapshotCronWorkflow).start if $0 == __FILE__
