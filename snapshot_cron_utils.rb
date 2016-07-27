require 'aws-sdk-v1'
require 'aws/decider'
require 'inifile'
require 'pathname'

class SnapshotCronUtils
  WF_VERSION = "1.0"
  ACTIVITY_VERSION = "1.0"
  WF_TASK_LIST = "sc_workflow_task_list"
  ACTIVITY_TASK_LIST = "sc_activity_task_list"
  DOMAIN = "SnapshotCron"

  # get inifile value
  def get_ini_value(inifile, section, name)
    begin
      return inifile[section][name]
    rescue => e
      return "error: could not read #{name}"
    end
  end

  def initialize(profile="default")
    # load ~/.aws inifiles
    aws_path = Pathname.new("~/.aws")

    # load config
    config_path = aws_path + "config"
    config_ini = IniFile.load(config_path.expand_path)
    region = get_ini_value(config_ini, profile, "region")

    # load credentials
    credentials_path = aws_path + "credentials"
    credentials_ini = IniFile.load(credentials_path.expand_path)
    aws_id = get_ini_value(credentials_ini, profile, "aws_access_key_id")
    aws_key = get_ini_value(credentials_ini, profile, "aws_secret_access_key")

    # set aws config
    AWS.config({
      :access_key_id => aws_id,
      :secret_access_key => aws_key,
      :region => region,
    })

    # create swf client
    swf_client = AWS::SimpleWorkflow.new

    # get domain 
    @domain = swf_client.domains[DOMAIN]
    unless @domain.exists?
      @domain = swf_client.domains.create(DOMAIN, 10)
    end
  end

  def activity_worker(klass)
    AWS::Flow::ActivityWorker.new(@domain.client, @domain, ACTIVITY_TASK_LIST, klass)
  end

  def workflow_worker(klass)
    AWS::Flow::WorkflowWorker.new(@domain.client, @domain, WF_TASK_LIST, klass)
  end

  def workflow_client(klass)
    AWS::Flow::workflow_client(@domain.client, @domain) { { from_class: klass.name } }
  end
  
end
