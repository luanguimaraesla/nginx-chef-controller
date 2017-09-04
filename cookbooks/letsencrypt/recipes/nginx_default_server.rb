link "/etc/nginx/sites-enabled/default" do
  to "/etc/nginx/sites-available/default-server"
end

service 'nginx' do
  action :restart
end
