# encoding: UTF-8
#
# Cookbook Name:: chef-nsq
# Recipe:: nsqlookupd
# Author:: Eric Lubow <elubow@simplereach.com>
# Author:: Matt Reiferson <snakes@gmail.com>
#
# Description:: Installs nsqlookupd
#

include_recipe 'nsq'

nsq_release = "nsq-#{node['nsq']['version']}-#{node['nsq']['go_version']}"

provider = Chef::Provider::Service::Upstart
if node.platform?('ubuntu') && node['platform_version'].to_f >= 18.04
  provider = Chef::Provider::Service::Systemd
end

if node['nsq']['setup_services']
  if provider == Chef::Provider::Service::Upstart
    template '/etc/init/nsqlookupd.conf' do
      action :create
      source 'upstart.nsqlookupd.conf.erb'
      mode '0644'
      # need to stop/start in order to reload config
      if node['nsq']['reload_services']
        notifies :stop, 'service[nsqlookupd]', :immediately
        notifies :start, 'service[nsqlookupd]', :immediately
      end
    end
  else
    template "#{node['chef-nsq']['script_dir']}/nsqlookupd-start.sh" do
      action :create
      source 'nsqlookupd-start.sh.erb'
      mode '0550'
      owner node['nsq']['nsqlookupd']['user']
      group node['nsq']['nsqlookupd']['user']
    end

    template '/etc/systemd/system/nsqlookupd.service' do
      action :create
      source 'systemd.nsqlookupd.conf.erb'
      mode '0644'
      notifies :run, 'execute[systemctl-daemon-reload]'
      # need to stop/start in order to reload config
      if node['nsq']['reload_services']
        notifies :stop, 'service[nsqlookupd]', :immediately
        notifies :start, 'service[nsqlookupd]', :immediately
      end
    end

    execute 'systemctl-daemon-reload' do
      command 'systemctl daemon-reload'
      action :nothing
    end
  end

  service 'nsqlookupd' do
    provider provider
    action [:enable, :start]
    supports stop: true, start: true, restart: true, status: true
    # Conditionally subscribe to version updates
    if node['nsq']['reload_services']
      subscribes :restart, "ark[#{nsq_release}]", :delayed
    end
  end
end
