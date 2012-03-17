require "mason"
require "mason/buildpacks"
require "mason/version"
require "thor"
require "thor/shell/basic"

class Mason::CLI < Thor

  class_option :help, :type => :boolean, :aliases => "-h", :desc => "help for this command"

  map %w( -v -V --version ) => :version

  desc "version", "display version"

  def version
    puts "mason v#{Mason::VERSION}"
  end

  desc "build APP", "build an app"

  method_option :output, :type => :string, :aliases => "-o", :desc => "output location"

  def build(app)
  end

  desc "buildpacks", "list installed buildpacks"

  def buildpacks
    buildpacks = Mason::Buildpacks.buildpacks

    puts "* buildpacks (#{Mason::Buildpacks.root})"
    buildpacks.keys.sort.each do |name|
      puts "  = #{name}: #{buildpacks[name]}"
    end

    puts "  - no buildpacks installed, use buildpacks:add" if buildpacks.length.zero?
  rescue StandardError => ex
    raise Mason::CommandFailed, ex.message
  end

  class Buildpacks < Thor

    desc "buildpacks:install URL", "install a buildpack"

    def install(url)
      puts "* adding buildpack #{url}"
      Mason::Buildpacks.install url
    rescue StandardError => ex
      raise Mason::CommandFailed, ex.message
    end

    desc "buildpacks:uninstall NAME", "uninstall a buildpack"

    def uninstall(name)
      puts "* removing buildpack #{name}"
      Mason::Buildpacks.uninstall name
    rescue StandardError => ex
      raise Mason::CommandFailed, ex.message
    end

  end

  # hack thor
  def self.run
    args   = ARGV.dup
    parts  = args.first.to_s.split(":")
    method = parts.pop
    ns     = parts.pop

    args[0] = method

    klass = case ns
      when "buildpacks" then Buildpacks
      else self
    end

    unless (args & %w( -h --help )).empty?
      klass.task_help(Thor::Shell::Basic.new, args.first)
      return
    end

    klass.start(args)
  end

end
