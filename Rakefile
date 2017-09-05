require 'yaml'
hosts_config_dir = "hosts"

ssh_config_file = "config/#{hosts_config_dir}/ssh_config"
ips_file = "config/#{hosts_config_dir}/ips.yaml"
certificate_domains_file = "config/#{hosts_config_dir}/certificate_domains.yaml"

ENV['CHAKE_SSH_CONFIG'] = ssh_config_file
ENV['CHAKE_RSYNC_OPTIONS'] = " --exclude backups"

require "chake"

ips ||= YAML.load_file(ips_file)
crt_domains ||= YAML.load_file(certificate_domains_file)

$nodes.each do |node|
  node.data['peers'] = ips
  node.data['crt_domains'] = crt_domains
end

require 'optparse'

def ssh_cmd(cmd, host)
  sh 'ssh', '-F', ENV['CHAKE_SSH_CONFIG'], host, cmd
end

def scp_cmd(file, dest, host, flags='')
  sh 'scp', flags,'-F', ENV['CHAKE_SSH_CONFIG'], file, "#{host}:#{dest}"
end

#Rake.add_rakelib 'lib/tasks'
