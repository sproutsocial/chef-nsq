# encoding: UTF-8
#
# Cookbook Name:: chef-nsq
# Recipe:: nsqadmin
# Author:: Eric Lubow <elubow@simplereach.com>
# Author:: Matt Reiferson <snakes@gmail.com>
#
# Description:: installs the NSQ Admin tool
#

include_recipe 'nsq'

nsq_release = "nsq-#{node['nsq']['version']}-#{node['nsq']['go_version']}"

if node['nsq']['setup_services']

  if node.platform?('ubuntu') && node['platform_version'].to_f >= 18.04

    template '/etc/systemd/system/nsqadmin.service' do
      action :create
      source 'systemd.nsqadmin.conf.erb'
      mode '0644'
      notifies :run, 'systemd_unit[nsqadmin.service]', :delayed
      # need to stop/start in order to reload config
      if node['nsq']['reload_services']
        notifies :stop, 'service[nsqadmin]', :immediately
        notifies :start, 'service[nsqadmin]', :immediately
      end
    end

    template "#{node['chef-nsq']['script_dir']}/nsqadmin-start.sh" do
      action :create
      source 'nsqadmin-start.sh.erb'
      mode '0550'
      owner node['nsq']['nsqadmin']['user']
      group node['nsq']['nsqadmin']['user']
    end

    systemd_unit 'nsqadmin.service' do
      action :nothing
    end

  else
    template '/etc/init/nsqadmin.conf' do
      action :create
      source 'upstart.nsqadmin.conf.erb'
      mode '0644'
      # need to stop/start in order to reload config
      if node['nsq']['reload_services']
        notifies :stop, 'service[nsqadmin]', :immediately
        notifies :start, 'service[nsqadmin]', :immediately
      end
    end
  end

  service 'nsqadmin' do
    action [:enable, :start]
    supports stop: true, start: true, restart: true, status: true
    if node['nsq']['reload_services']
      subscribes :restart, "ark[#{nsq_release}]", :delayed
    end
  end
end
