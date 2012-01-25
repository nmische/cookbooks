#
# Cookbook Name:: railo331
# Recipe:: express
#
# Copyright 2012, Nathan Mische
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Download Railo Express (http://www.getrailo.org/index.cfm/download/)
remote_file "/tmp/railo-3.3.1.000-railo-express-with-jre-linux.tar.gz" do
  source "http://www.getrailo.org/railo/remote/download/3.3.1.000/railix/linux/railo-3.3.1.000-railo-express-with-jre-linux.tar.gz"
  action :create_if_missing
  mode "0744"
  owner "root"
  group "root"
end

# Extract the installer
execute "untar_installer" do
  command "tar -xvzf /tmp/railo-3.3.1.000-railo-express-with-jre-linux.tar.gz"
  creates "/tmp/railo-3.3.1.000-railo-express-with-jre-linux"
  action :run
  user "root"
  cwd "/tmp"
end

# Move the installation
execute "install" do
  command "mv /tmp/railo-3.3.1.000-railo-express-with-jre-linux #{node[:railo][:install_path]}"
  creates "#{node[:railo][:install_path]}"
  action :run
  user "root"
  cwd "/tmp"
end

# Update the init script
template "#{node[:railo][:install_path]}/bin/jetty.sh" do
  source "jetty.sh.erb"
  mode "0777"
  owner "root"
  group "root"
end

# Link the init script
execute "railo_init" do 
  command "ln -sf #{node[:railo][:install_path]}/bin/jetty.sh /etc/init.d/jetty"
  creates "/etc/init.d/jetty"
  action :run
  user "root"
  cwd "/tmp"
end

# Set up Jetty as a service
service "jetty" do
  start_command "/etc/init.d/jetty start"
  stop_command "/etc/init.d/jetty stop"
  restart_command "/etc/init.d/jetty restart"
  supports :status => false, :restart => true, :reload => false
  action [ :enable, :stop ]
end

# Move Railo Express webroot to new location
execute "railo_move_webroot" do 
  command "mv /opt/railo/webroot #{node[:railo][:webroot]}"
  creates "#{node[:railo][:webroot]}"
  action :run
  user "root"
  cwd "/opt"
  notifies :restart, "service[jetty]", :delayed
end

# Link the init script
execute "railo_link_webroot" do 
  command "ln -sf #{node[:railo][:webroot]} webroot"
  creates "webroot"
  action :run
  user "root"
  cwd "/opt/railo"
  notifies :restart, "service[jetty]", :delayed
end
