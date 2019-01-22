# encoding: UTF-8
#
# Cookbook Name:: chef-nsq
# Recipe:: nsqd
# Author:: Eric Lubow <elubow@simplereach.com>
# Author:: Matt Reiferson <snakes@gmail.com>
#
# Description:: Installs nsqd
#

include_recipe 'nsq'

chef_gem 'semantic' do
  compile_time true
end

require 'semantic'

nsq_release = "nsq-#{node['nsq']['version']}-#{node['nsq']['go_version']}"

# Create path for the on-disk queue files are stored
directory node['nsq']['nsqd']['data_path'] do
  action :create
  mode '0770'
  owner 'nsqd'
  group 'nsqd'
  recursive true
end

if node['nsq']['setup_services']

  if node.platform?('ubuntu') && node['platform_version'].to_f >= 18.04

    template '/srv/nsqd-start.sh' do
      action :create
      source 'nsqd-start.sh.erb'
      mode '0550'
      # mode '0777'
      owner 'nsqd'
      group 'nsqd'
    end

    template '/etc/systemd/system/nsqd.service' do
      action :create
      source 'systemd.nsqd.conf.erb'
      mode '0644'
      notifies :run, 'execute[systemctl-daemon-reload]'
      # need to stop/start in order to reload config
      if node['nsq']['reload_services']
        notifies :stop, 'service[nsqd]', :immediately
        notifies :start, 'service[nsqd]', :immediately
      end
    end

    execute 'systemctl-daemon-reload' do
      command 'systemctl daemon-reload'
      action :nothing
    end
  else
    template '/etc/init/nsqd.conf' do
      action :create
      source 'upstart.nsqd.conf.erb'
      mode '0644'
      # need to stop/start in order to reload config
      if node['nsq']['reload_services']
        notifies :stop, 'service[nsqd]', :immediately
        notifies :start, 'service[nsqd]', :immediately
      end
    end
  end

  service 'nsqd' do
    if node.platform?('ubuntu') && node['platform_version'].to_f >= 18.04
      provider Chef::Provider::Service::Systemd
      action [:enable, :start]
      supports stop: true, start: true, restart: true, status: true
      if node['nsq']['reload_services']
        subscribes :restart, "ark[#{nsq_release}]", :delayed
      end
    else
      provider Chef::Provider::Service::Upstart
      action [:enable, :start]
      supports stop: true, start: true, restart: true, status: true
      # Conditionally subscribe to version updates
      if node['nsq']['reload_services']
        subscribes :restart, "ark[#{nsq_release}]", :delayed
      end
    end
  end
end
