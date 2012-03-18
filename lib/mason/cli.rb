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

  method_option :buildpack, :type => :string, :aliases => "-b", :desc => "use a custom buildpack"
  method_option :output,    :type => :string, :aliases => "-o", :desc => "output location"
  method_option :type,      :type => :string, :aliases => "-t", :desc => "output type (dir, img, tgz)"

  def build(app)
    raise "no such directory: #{app}" unless File.exists?(app)

    type = options[:type]
    output = options[:output]

    type = File.extname(output)[1..-1] if !type && output
    output = "#{app}.#{type}" if !output && type
    type ||= "dir"

    raise "no such output format: #{type}" unless %w( dir img tgz ).include?(type)

    print "* detecting buildpack... "

    buildpack, ret = Mason::Buildpacks.detect(app)
    raise "no valid buildpack detected" unless buildpack

    puts "done"
    puts "  = name: #{buildpack.name}"
    puts "  = url: #{buildpack.url}"
    puts "  = display: #{ret}"

    puts "* compiling..."
    compile_dir = buildpack.compile(app)

    print "* packaging... "
    case type.to_sym
    when :tgz then
      Dir.chdir(compile_dir) do
        system %{ tar czf "#{output}" . }
      end
    when :img then
      puts "not yet"
    when :dir then
      FileUtils.rm_rf output
      FileUtils.cp_r compile_dir, output
    else
      raise "no such output type: #{type}"
    end
    puts "done"
    puts "  = type: #{type}"
    puts "  = location: #{output}"
  end

  desc "buildpacks", "list installed buildpacks"

  def buildpacks
    buildpacks = Mason::Buildpacks.buildpacks

    puts "* buildpacks (#{Mason::Buildpacks.root(false)})"
    buildpacks.sort.each do |buildpack|
      puts "  = #{buildpack.name}: #{buildpack.url}"
    end

    puts "  - no buildpacks installed, use buildpacks:add" if buildpacks.length.zero?
  end

  class Buildpacks < Thor

    desc "buildpacks:install URL", "install a buildpack"

    def install(url)
      puts "* adding buildpack #{url}"
      Mason::Buildpacks.install url
    end

    desc "buildpacks:uninstall NAME", "uninstall a buildpack"

    def uninstall(name)
      puts "* removing buildpack #{name}"
      Mason::Buildpacks.uninstall name
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
  # rescue StandardError => ex
  #   raise Mason::CommandFailed, ex.message
  end

end
