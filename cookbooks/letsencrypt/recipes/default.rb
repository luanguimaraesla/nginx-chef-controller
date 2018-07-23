# Recipe to install and configure nginx and letsencrypt

execute 'apt-get update'

packages = %w(nginx git bc)

packages.each do |a|
  package a
end

git '/opt/letsencrypt' do
  repository 'https://github.com/letsencrypt/letsencrypt'
  action :sync
end

cookbook_file '/etc/nginx/sites-available/default' do
  source 'nginx-default-config'
  owner 'root'
  group 'root'
  mode '0644'
end

link "/etc/nginx/sites-enabled/default" do
	to "/etc/nginx/sites-available/default"
end

execute 'remove server files' do
  command 'rm -rf *-server'
  cwd '/etc/nginx/sites-enabled/'
end

service 'nginx' do
  action :restart
end

file '/etc/nginx.services' do
  action :create_if_missing
end

ruby_block 'Check current cert domains' do
  block do
    def tracked_services_updated? services
      node['crt_domains'] == services
    end

    def generate_crt_domains_arg
      crt_domains = "-d #{default_domain}"
      node['crt_domains'].each do |key, value|
        crt_domains += " -d #{value['server_name']}" unless key == 'default'
      end

      crt_domains
    end

    def default_domain
      node['crt_domains']['default']['server_name']
    end

    def update_current_crt_dir(new_crt_dir, default_domain)
      unless new_crt_dir == default_domain
        system("rm -rf /etc/letsencrypt/live/#{default_domain}")
        system("mv /etc/letsencrypt/live/#{new_crt_dir} /etc/letsencrypt/live/#{default_domain}")
      end
    end

    def execute_openssl_dhparam_generator
      system("sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048")
    end

    def get_tracked_services
      YAML.load_file('/etc/nginx.services')
    end

    def update_crt_domains_tracker
      File.open('/etc/nginx.services','w') do |f|
        f.write node['crt_domains'].to_hash.to_yaml
      end
    end

    def execute_letsencrypt_crt_generator crt_domains
      system("/opt/letsencrypt/letsencrypt-auto certonly -a webroot\
             --renew-by-default --email centeias.unb@gmail.com\
             --webroot-path=/var/www/html #{crt_domains} --agree-tos\
             --non-interactive")
      execute_openssl_dhparam_generator
    end

    def get_newest_crt_directory
      absolute_crt_dirs = Dir.glob('/etc/letsencrypt/live/*')
      relative_crt_dirs = absolute_crt_dirs.map { |f| f.split('/').last }
      newest_crt_dir = relative_crt_dirs.sort.last
    end

		services = get_tracked_services
    unless tracked_services_updated? services
      # Genereting new certificates
      crt_domains_arg = generate_crt_domains_arg
      execute_letsencrypt_crt_generator crt_domains_arg
      update_crt_domains_tracker

#      newest_crt_dir = get_newest_crt_directory
#      update_current_crt_dir(newest_crt_dir, default_domain)
    end
  end
end

cookbook_file '/etc/nginx/sites-available/default' do
  source 'nginx-ssl-config'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

#include_recipe 'letsencrypt::nginx_default_server'
