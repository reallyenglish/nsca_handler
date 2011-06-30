

require 'rubygems'
require 'chef/log'
require 'chef'
require 'chef/config'

class NSCAHandler < Chef::Handler
  def initialize
    @w_elapsed_time  = Chef::Config['elapsed_time_warning']       || 30
    @c_elapsed_time  = Chef::Config['elapsed_time_critical']      ||  60 
    @c_updated_res   = Chef::Config['updated_resources_critical'] ||  20 
    @w_updated_res   = Chef::Config['updated_resources_warning']  ||  5
    @send_nsca_binary= Chef::Config['send_nsca_binary']                || '/usr/sbin/send_nsca'
    @service_name    = Chef::Config['service_name']                    || 'Chef client run status'

  end
  def report
    ret=''
    if run_status.failed? || (run_status.elapsed_time > @c_elapsed_time.to_i ) || (run_status.updated_resources.length > @c_updated_res.to_i)
      ret=2 
      Chef::Log.info( "Setiing host status critincal:#{run_status.failed?} | #{run_status.elapsed_time} | #{@c_elapsed_time.to_i} | #{run_status.updated_resources.length} | #{@c_updated_res.to_i}")
    elsif (run_status.elapsed_time > @w_elapsed_time.to_i) || (run_status.updated_resources.length > @w_updated_res.to_i)
      Chef::Log.info( "Setting host status warning  : #{run_status.elapsed_time} | #{@w_elapsed_time.to_i} | #{run_status.updated_resources.length}")
      ret=1
    else
      ret=0
    end
    host_name= Chef::Config['nagios_hostname'] || run_status.node[:fqdn]
    msg_string="#{host_name}\t#{@service_name}\t#{ret}\tStart:#{run_status.start_time}\tTime:#{run_status.elapsed_time}\tUpdated:#{run_status.updated_resources.length}\tAll:#{run_status.all_resources.length}\n"
    Chef::Log.info("send_nsca msg_string : #{msg_string}")
    Chef::Log.info(`echo \"#{msg_string}\" | #{@send_nsca_binary} -H #{node[:chefclient][:nsca_server]}`)
  end
end
