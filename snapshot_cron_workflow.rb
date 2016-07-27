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
    # get ec2 list
    on_demand, spot = client.get_active_ec2_list()

    # for spot
    result_spot = false
    result_spot = client.create_ami_spot(spot)
    if result_spot then 
      puts "spot instances operations finished !!"
    else
      puts "spot instances not exist"
    end

    # for on demand
    result_on_demand = false
    result_on_demand = client.create_ami_on_demand(on_demand)
    if result_on_demand then 
      puts "on demand instances operations finished !!"
    else
      puts "on demand instances not exist"
    end

  end
end

SnapshotCronUtils.new.workflow_worker(SnapshotCronWorkflow).start if $0 == __FILE__
