require 'serverspec'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

RSpec.configure do |c|
  c.before :all do
    c.path = '/sbin:/usr/sbin'
  end
end

describe "Apache2 with mod_security" do

  it "is listening on port 80" do
    expect(port(80)).to be_listening
  end

  it "has a running service of apache2" do
    expect(service("apache2")).to be_running
  end

  it "has a mod-security configuration file" do
    expect(file("/etc/apache2/mods-enabled/mod-security.conf")).to be_file
  end

  it "has a mod-security load file" do
    expect(file("/etc/apache2/mods-enabled/mod-security.load")).to be_file
  end

end
