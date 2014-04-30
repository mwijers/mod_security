# install package common to package and source install
case node[:platform_family]
when 'rhel', 'fedora', 'suse'
  packages = %w[apr apr-util pcre-devel libxml2-devel curl-devel]
when 'ubuntu', 'debian'
  packages = %w[libapr1 libaprutil1 libpcre3 libxml2 libcurl3]
when 'arch'
  packages = %w[apr apr-util pcre libxml2 lib32-curl]
when 'freebsd'
  packages = %w[apr pcre-8.33 libxml2 curl]
else
  Chef::Log.fatal("Unsupported platform: #{node[:platform_family]}.")
  fail 'mod_security cookbook does not support this platform'
end
packages.each { |p| package p }

# FIXME: ignoring lua for right now
# make optional in the future

if node[:mod_security][:from_source]
  # COMPILE FROM SOURCE
  include_recipe 'locales'
  include_recipe 'build-essential::default'

  # install required libs

  case node[:platform_family]
  when 'arch'
    # OH NOES
  when 'rhel', 'fedora', 'suse'
    package 'httpd-devel'
    if node[:platform_version].to_f < 6.0
      package 'curl-devel'
    else
      package 'libcurl-devel'
      package 'openssl-devel'
      package 'zlib-devel'
    end
  when 'debian'
    apache_development_package =  if %w( worker threaded ).include? node[:mod_security][:apache_mpm]
                                    'apache2-threaded-dev'
                                  else
                                    'apache2-prefork-dev'
                                  end
    %W( #{apache_development_package} libxml2-dev libcurl4-openssl-dev ).each do |pkg|
      package pkg
    end
  end

  # Create directories

  directory "#{node[:mod_security][:dir]}"

  %W( #{node[:mod_security][:tmp_dir]} #{node[:mod_security][:data_dir]} ).each do |dir|
    directory dir do
      owner node[:apache][:user]
      group node[:apache][:group]
      mode 00755
      not_if { dir == '/tmp/' }
    end
  end

  # Download and compile mod_security from source
  ark 'modsecurity' do
    url node[:mod_security][:source_dl_url]
    version node[:mod_security][:source_version]
    checksum node[:mod_security][:source_checksum]
    action :configure
    notifies :run, 'execute[make_mod_security]', :immediately
  end

  execute 'make_mod_security' do
    command 'make clean && make && make mlogc'
    cwd "/usr/local/modsecurity-#{node[:mod_security][:source_version]}"
    action :nothing
    notifies :run, 'execute[install_mod_security]', :immediately
  end

  execute 'install_mod_security' do
    command 'make install'
    cwd "/usr/local/modsecurity-#{node[:mod_security][:source_version]}"
    action :nothing
  end

  # setup apache module loading
  apache_module 'unique_id'

  unless platform_family?('rhel', 'fedora', 'arch', 'suse', 'freebsd')
    template "#{node[:apache][:dir]}/mods-available/mod-security.load" do
      source 'mods/mod-security.load.erb'
      owner node[:apache][:user]
      group node[:apache][:group]
      mode 0644
      # backup false
      notifies :restart, 'service[apache2]', :delayed
    end
  end

  template "#{node[:apache][:dir]}/mods-available/mod-security.conf" do
    source 'mods/mod-security.conf.erb'
    owner node[:apache][:user]
    group node[:apache][:group]
    mode 0644
    # backup false
    notifies :restart, 'service[apache2]', :delayed
  end

  apache_module 'mod-security' do
    conf true
    # The following attributes are only used by the apache2 cookbook on rhel, fedora, arch, suse and freebsd
    # as it only drop off a .load file for those platforms
    identifier node[:mod_security][:source_module_identifier]
    module_path "#{node[:mod_security][:source_module_path]}/#{node[:mod_security][:source_module_name]}"
  end

  cookbook_file "unicode.mapping" do
    path "#{node[:mod_security][:dir]}/unicode.mapping"
    action :create
    notifies :restart, 'service[apache2]', :delayed
  end

else
  # INSTALL FROM PACKAGE
  case node[:platform_family]
  when 'rhel', 'fedora', 'suse'
    package 'mod_security'
  when 'debian'
    package 'libapache-mod-security'
  when 'arch'
    package 'modsecurity-apache'
  end
end

directory node[:mod_security][:rules] do
  recursive true
end

template 'modsecurity.conf' do
  path node[:mod_security][:base_config]
  source 'modsecurity.conf.erb'
  owner node[:apache][:user]
  group node[:apache][:group]
  mode 0644
  backup false
  notifies :restart, 'service[apache2]'
end
