require "pathname"

require "fileutils"
include FileUtils

class TestCM
  def initialize
    @base = Pathname("../nps/gen/install/linux")
    @instance = base + "instance/seslucenmy"
  end

  attr_reader :base, :instance

  def setup
    teardown
    system "#{base}/share/createInstance/createInstance --interactive 0\
        --licenseFile #{base.realpath}/instance/default/config/license.xml\
        --instanceName seslucenmy --portStart 4700"
    system "#{base}/share/dbInstall/install-db --interactive 0 --dbType mysql\
        --appName cm --serverName localhost --databaseName test_ses_lucene\
        --adminName root --adminPassword \"\" --user test_ses_lucene\
        --password test_ses_lucene --port 3306"
    cp "#{base}/share/dbInstall/cmdb.xml", "#{instance}/config"

    indexing_config = File.read("#{instance}/config/indexing.xml")
    open("#{instance}/config/indexing.xml", "w") do |f|
      f << indexing_config.gsub(%!<isActive>true</isActive>!,
                                %!<isActive>false</isActive>!)
    end

    system "#{instance}/bin/CM -restore #{base}/share/initDump"
    system "#{instance}/bin/CM -railsify"
    cp "objectChangedCallback.tcl", "#{instance}/script/cm/serverCmds/"
    cp "publish_object_changes.rb", "#{instance}/script/cm/serverCmds/"
  end

  def teardown
    rm_rf instance
  end

  def tcl(cmd)
    open("|#{instance}/bin/CM -single", "w") do |tcl|
      tcl << cmd
    end
  end
end