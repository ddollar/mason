require "clamp"
require "mason"
require "mason/buildpacks"
require "mason/version"

class Mason::CLI < Clamp::Command

  option %w( -v --version ), :flag, "show version and exit" do
    puts "mason v#{Mason::VERSION}"
    exit 0
  end

  subcommand "buildpacks", "list installed buildpacks" do

    def execute
      buildpacks = Mason::Buildpacks.buildpacks

      puts "* buildpacks (#{Mason::Buildpacks.root})"
      buildpacks.keys.sort.each do |name|
        puts "  = #{name}: #{buildpacks[name]}"
      end

      puts "  - no buildpacks installed, use buildpacks:add" if buildpacks.length.zero?
    rescue StandardError => ex
      raise Mason::CommandFailed, ex.message
    end

  end

  subcommand "buildpacks:add", "install a buildpack" do

    parameter "URL", "buildpack url to install"

    def execute
      puts "* adding buildpack #{url}"
      Mason::Buildpacks.install url
    rescue StandardError => ex
      raise Mason::CommandFailed, ex.message
    end

  end

  subcommand "buildpacks:remove", "uninstall a buildpack" do

    parameter "BUILDPACK", "buildpack name to uninstall"

    def execute
      puts "* removing buildpack #{buildpack}"
      Mason::Buildpacks.uninstall buildpack
    rescue StandardError => ex
      raise Mason::CommandFailed, ex.message
    end

  end

end
