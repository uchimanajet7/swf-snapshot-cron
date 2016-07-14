require 'aws-sdk-resources'
require_relative 'snapshot_cron_utils'

class SnapshotCronActivity
  extend AWS::Flow::Activities

  activity :get_active_ec2_list, :create_ami, :stop_ec2, :start_ec2 do
    {
      version: SnapshotCronUtils::ACTIVITY_VERSION,
      default_task_list: SnapshotCronUtils::ACTIVITY_TASK_LIST,
      default_task_schedule_to_start_timeout: 30,
      default_task_start_to_close_timeout: 60
    }
  end

  # list ec2 
  def get_active_ec2_list()
    on_demand = Array.new
    spot = Array.new

    ec2 = Aws::EC2::Resource.new
    ec2.instances.each{|i|
      if i.state.name == "running" then
        if i.spot_instance_request_id != nil then
          spot.push(i)
        else
          on_demand.push(i)
        end
      end
    }
    return on_demand, spot
  end

  def create_ami(instance_obj, no_reboot=false)
    timestamp = Time.now.strftime("%Y%m%d%H%M")
    title = "#{instance_obj.id}-#{timestamp}"
    ami = instance_obj.create_image(name: title, description: title, no_reboot: no_reboot)
    puts "AMI creating! Plz Wait"
    ec2 = Aws::EC2::Client.new
    wa = ec2.wait_until(:image_available, image_ids: [ami.id])
    puts "success create"
    return ami
  end

  def stop_ec2(instance_obj)
    result = instance_obj.stop
    puts "Stop EC2"
    i = instance_obj.wait_until_stopped
    puts "success stop"
    return i
  end

  def start_ec2(instance_obj)
    result = instance_obj.start
    puts "Start EC2"
    i = instance_obj.wait_until_running
    puts "success start"
    return i
  end
 
end

SnapshotCronUtils.new.activity_worker(SnapshotCronActivity).start if $0 == __FILE__
