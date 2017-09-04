node['crt_domains'].each do | server, params |
  template "/etc/nginx/sites-available/#{ server }-server" do
    source(server != 'default' ? "server_conf.erb" : "default_server_conf.erb")
    variables({
      server:       server,
      server_ip:    node['peers']["#{server}"] || node['peers']['nginx'],
      service_port: params['service_port'],
      server_name:  params['server_name']
    })
    mode 0644
  end

  if server != 'default'
    link "/etc/nginx/sites-enabled/#{server}-server" do
      to "/etc/nginx/sites-available/#{server}-server"
    end
  end
end

service 'nginx' do
  action :restart
end
