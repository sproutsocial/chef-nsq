# encoding: UTF-8

# Versions
default['nsq']['version'] = '0.3.0'
default['nsq']['go_version'] = 'go1.3.3'

# Architecture
default['nsq']['arch'] = 'linux-amd64'

# Should we setup upstart services?
default['nsq']['setup_services'] = true

# Should we reload services on config changes?
default['nsq']['reload_services'] = false

# Release URL. Defaults to bitly upstream
default['nsq']['release_url'] = 'https://s3.amazonaws.com/bitly-downloads/nsq'

# What logger binary to use for shipping logs. This needs to act like
# logger(1) and at least support a -t parameter for tags.
default['nsq']['logger_bin'] = 'logger'

# Systemd start scripts will be placed here
default['chef-nsq']['script_dir'] = '/srv'
