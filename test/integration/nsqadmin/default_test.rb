describe service('nsqadmin') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe http('http://127.0.0.1:4171/') do
  its('status') { should cmp 200 }
end
