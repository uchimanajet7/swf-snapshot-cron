require 'aws-sdk-core'
require 'aws/decider'

class SnapshotCronUtils
  WF_VERSION = "1.0"
  ACTIVITY_VERSION = "1.0"
  WF_TASK_LIST = "sc_workflow_task_list"
  ACTIVITY_TASK_LIST = "sc_activity_task_list"
  DOMAIN = "SnapshotCron_7141535"
  Aws.config[:region] = 'ap-northeast-1'

  def initialize
    # create swf client
    @swf_client = Aws::SWF::Client.new

    # try register new domain
    begin
      resp = @swf_client.register_domain({
        name: DOMAIN,
        workflow_execution_retention_period_in_days: "10",
        })
    rescue => e
      p e
    end
    
    # get domain info
    resp = @swf_client.describe_domain({name: DOMAIN,})
    @domain = resp.domain_info

    p @domain
  end

  def activity_worker(klass)
    AWS::Flow::ActivityWorker.new(@swf_client, @domain, ACTIVITY_TASK_LIST, klass)
  end

  def workflow_worker(klass)
    AWS::Flow::WorkflowWorker.new(@swf_client, @domain, WF_TASK_LIST, klass)
  end

  def workflow_client(klass)
    AWS::Flow::workflow_client(@swf_client, @domain) { { from_class: klass.name } }
  end

end
