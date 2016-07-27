require 'aws-sdk-resources'
require_relative 'snapshot_cron_utils'

class SnapshotCronActivity
  extend AWS::Flow::Activities

  activity :get_active_ec2_list, :create_ami_on_demand, :create_ami_spot do
    {
      version: SnapshotCronUtils::ACTIVITY_VERSION,
      default_task_list: SnapshotCronUtils::ACTIVITY_TASK_LIST,
      default_task_schedule_to_start_timeout: 30,
      default_task_start_to_close_timeout: 300,
    }
  end

  # return display formatted date time
  def get_log_disp_time
    return Time.now.strftime("%Y-%m-%d %H:%M:%S")
  end

  # list ec2 
  def get_active_ec2_list()
    on_demand = []
    spot = []

    ec2 = AWS::EC2.new
    ec2.instances.each{|i|
      if i.status == :running then
        if i.spot_instance? then
          spot << i.id
        else
          on_demand << i.id
        end
      end
    }
    return on_demand, spot
  end

  # for on demand
  def create_ami_on_demand(ids)
    result = false
    if !ids.empty? then
      result = true
      ids.each{|i|
        puts "#{get_log_disp_time} = Start operation for [on demand] instance / id:[#{i}]"

        stop_ec2(i)
        create_ami(i, true)
        start_ec2(i)

        puts "#{get_log_disp_time} = Stop operation for [on demand] instance / id:[#{i}]"
     }
    end
    return result
  end

  # for spot
  def create_ami_spot(ids)
    result = false
    if !ids.empty? then
      result = true
      ids.each{|i|
        puts "#{get_log_disp_time} = Start operation for [spot] instance / id:[#{i}]"

        create_ami(i, true)

        puts "#{get_log_disp_time} = Stop operation for [spot] instance / id:[#{i}]"
     }
    end
    return result
  end

  # create AMI
  def create_ami(id, no_reboot=false)
    ec2 = AWS::EC2.new
    ec2_obj = ec2.instances[id]

    timestamp = Time.now.strftime("%Y%m%d%H%M")
    title = "#{ec2_obj.id}-#{timestamp}"
    ami = ec2_obj.create_image(title, description: title, no_reboot: no_reboot)

    # wait until image available
    puts "#{get_log_disp_time} - Creating AMI / id:[#{ami.id}]"
    until ami.state == :available do
      puts "#{get_log_disp_time} --- Wait until available AMI / id:[#{ami.id}]"
      sleep(15)
    end
    puts "#{get_log_disp_time} - Available AMI / id:[#{ami.id}]"
    
    return ami
  end

  # stop ec2 instance
  def stop_ec2(id)
    ec2 = AWS::EC2.new
    ec2_obj = ec2.instances[id]
    ec2_obj.stop

    # wait until instance status stopped
    puts "#{get_log_disp_time} - Stopping EC2 Instance / id:[#{ec2_obj.id}]"
    until ec2_obj.status == :stopped do
      puts "#{get_log_disp_time} --- Wait until stopping EC2 Instance / id:[#{ec2_obj.id}]"
      sleep(15)
    end
    puts "#{get_log_disp_time} - Stopped EC2 Instance / id:[#{ec2_obj.id}]"
  end

  # start ec2 instance
  def start_ec2(id)
    ec2 = AWS::EC2.new
    ec2_obj = ec2.instances[id]
    ec2_obj.start

    # wait until instance status running
    puts "#{get_log_disp_time} - Starting EC2 Instance / id:[#{ec2_obj.id}]"
    until ec2_obj.status == :running do
      puts "#{get_log_disp_time} --- Wait until running EC2 Instance / id:[#{ec2_obj.id}]"
      sleep(5)
    end
    puts "#{get_log_disp_time} - Running EC2 Instance / id:[#{ec2_obj.id}]"
  end
 
end

SnapshotCronUtils.new.activity_worker(SnapshotCronActivity).start if $0 == __FILE__
