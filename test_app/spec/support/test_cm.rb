class TestCM

  attr_reader :base, :instance

  def initialize
    @base = Pathname("~/nps").expand_path
    @instance = base + "instance/seslucenmy"
  end

  def setup
    teardown
    system "#{base}/share/createInstance/createInstance --interactive 0\
        --licenseFile #{base.realpath}/instance/default/config/license.xml\
        --instanceName seslucenmy --portStart 4700"
    system "#{base}/share/dbInstall/install-db --interactive 0 --dbType mysql\
        --appName cm --serverName localhost --databaseName test_ses_lucene\
        --adminName root --adminPassword \"\" --user test_ses_lucene\
        --password test_ses_lucene --port 3306"
    FileUtils.cp "#{base}/share/dbInstall/cmdb.xml", "#{instance}/config/"

    indexing_config = File.read("#{instance}/config/indexing.xml")
    open("#{instance}/config/indexing.xml", "w") do |f|
      f << indexing_config.gsub(%!<isActive>true</isActive>!,
                                %!<isActive>false</isActive>!)
    end

    system "#{instance}/bin/CM -restore #{base}/share/initDump"
    system "#{instance}/bin/CM -railsify"
    system "gem install vendor/cache/resque-*.gem --no-ri --no-rdoc --no-user-install --install-dir #{instance}/script/gems"
    system "gem install vendor/cache/json-*.gem --no-ri --no-rdoc --no-user-install --install-dir #{instance}/script/gems"
    FileUtils.cp "../cms-callback/objectChangedCallback.tcl", "#{instance}/script/cm/serverCmds/"
    FileUtils.cp "../cms-callback/publish_object_changes.rb", "#{instance}/script/cm/serverCmds/"
  end

  def teardown
    FileUtils.rm_rf instance
  end

  def tcl(cmd)
    open("|#{instance}/bin/CM -single", "w") do |tcl|
      tcl << cmd
    end
  end
end
