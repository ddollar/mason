require "clamp"
require "mason"
require "mason/buildpack"
require "mason/version"

class Mason::CLI < Clamp::Command

  option %w( -v --version ), :flag, "show version and exit" do
    puts "mason v#{Mason::VERSION}"
    exit 0
  end

  subcommand "buildpacks", "list installed buildpacks" do

    def execute
      Mason::Buildpack.list
    rescue StandardError => ex
      raise Mason::CommandFailed, ex.message
    end

  end

  subcommand "buildpacks:add", "install a buildpack" do

    parameter "URL", "buildpack url to install"

    def execute
      Mason::Buildpack.install url
    rescue StandardError => ex
      raise Mason::CommandFailed, ex.message
    end

  end

  subcommand "buildpacks:remove", "uninstall a buildpack" do

    parameter "BUILDPACK", "buildpack name to uninstall"

    def execute
      Mason::Buildpack.uninstall buildpack
    rescue StandardError => ex
      raise Mason::CommandFailed, ex.message
    end

  end

end
