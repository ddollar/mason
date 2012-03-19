require "mason"
require "mason/buildpacks"
require "mason/stacks"
require "mason/version"
require "thor"
require "thor/shell/basic"

class Mason::CLI < Thor

  class_option :debug, :type => :boolean, :desc => "show backtraces"
  class_option :help, :type => :boolean, :aliases => "-h", :desc => "help for this command"

  map %w( -v -V --version ) => :version

  desc "version", "display version"

  def version
    puts "mason v#{Mason::VERSION}"
  end

  desc "build APP", "build an app"

  method_option :buildpack, :type => :string, :aliases => "-b", :desc => "use a custom buildpack"
  method_option :output,    :type => :string, :aliases => "-o", :desc => "output location"
  method_option :quiet,     :type => :boolean, :aliases => "-q", :desc => "quiet packaging output"
  method_option :stack,     :type => :string, :aliases => "-s", :desc => "use a stack for building"
  method_option :type,      :type => :string, :aliases => "-t", :desc => "output type (dir, img, tgz)"

  def build(app)
    app = File.expand_path(app)

    raise "no such directory: #{app}" unless File.exists?(app)

    type = options[:type]
    output = options[:output]

    type = File.extname(output)[1..-1] if !type && output
    output = "#{app}.#{type}" if !output && type

    type   ||= "dir"
    output ||= "/tmp/mason.out"

    output = File.expand_path(output)

    raise "no such output format: #{type}" unless %w( dir img tgz ).include?(type)

    if stack = options[:stack]
      print "* booting stack #{stack} (this may take a while)... "
      Mason::Stacks.up(stack)
      puts "done"

      buildpacks_dir = File.expand_path("~/.mason/share/#{stack}/buildpacks")
      compile_dir = File.expand_path("~/.mason/share/#{stack}/app")
      mason_dir = File.expand_path("~/.mason/share/#{stack}/mason")

      FileUtils.rm_rf buildpacks_dir
      FileUtils.rm_rf compile_dir
      FileUtils.rm_rf mason_dir

      FileUtils.cp_r File.expand_path("~/.mason/buildpacks"), buildpacks_dir
      FileUtils.cp_r app, compile_dir
      FileUtils.cp_r File.expand_path("../../../", __FILE__), mason_dir

      mason_args =  %{ /share/app -q -o /share/output -t #{type} }
      mason_args += %{ -b "#{options[:buildpack]}" } if options[:buildpack]

      Mason::Stacks.run(stack, <<-COMMAND)
        gem spec thor 2>&1 >/dev/null || sudo gem install thor
        /usr/bin/env ruby -rubygems /share/mason/bin/mason build #{mason_args}
      COMMAND

      FileUtils.cp_r File.expand_path("~/.mason/share/#{stack}/output"), output

      puts "* packaging"
      puts "  = type: #{type}"
      puts "  = location: #{output}"
    else
      print "* detecting buildpack... "

      buildpack, ret = Mason::Buildpacks.detect(app)
      raise "no valid buildpack detected" unless buildpack

      puts "done"
      puts "  = name: #{buildpack.name}"
      puts "  = url: #{buildpack.url}"
      puts "  = display: #{ret}"

      puts "* compiling..."
      compile_dir = buildpack.compile(app)

      print "* packaging... " unless options[:quiet]
      case type.to_sym
      when :tgz then
        Dir.chdir(compile_dir) do
          system %{ tar czf "#{output}" . }
        end
      when :img then
        raise "img not supported yet"
      when :dir then
        FileUtils.rm_rf output
        FileUtils.cp_r compile_dir, output
      else
        raise "no such output type: #{type}"
      end

      unless options[:quiet]
        puts "done"
        puts "  = type: #{type}"
        puts "  = location: #{output}"
      end
    end

  end

  desc "vagrant COMMAND", "run a vagrant command in the mason environment"

  def vagrant(*args)
    Mason::Stacks.vagrant(args)
  end

  desc "buildpacks", "list installed buildpacks"

  def buildpacks
    buildpacks = Mason::Buildpacks.buildpacks

    puts "* buildpacks (#{Mason::Buildpacks.root(false)})"
    buildpacks.sort.each do |buildpack|
      puts "  = #{buildpack.name}: #{buildpack.url}"
    end

    puts "  - no buildpacks installed, use buildpacks:install" if buildpacks.length.zero?
  end

  class Buildpacks < Thor

    desc "buildpacks:install URL", "install a buildpack"

    def install(url)
      puts "* installing buildpack #{url}"
      Mason::Buildpacks.install url
    end

    desc "buildpacks:uninstall NAME", "uninstall a buildpack"

    def uninstall(name)
      puts "* uninstalling buildpack #{name}"
      Mason::Buildpacks.uninstall name
    end

  end

  desc "stacks", "list available stacks"

  def stacks
    stacks = Mason::Stacks.stacks

    puts "* available stacks"
    stacks.keys.each do |name|
      puts "  - #{name} [#{Mason::Stacks.state(name)}]"
    end

    puts "  - no stacks created, use stacks:create" if stacks.length.zero?
  end

  class Stacks < Thor

    # Hackery. Take the run method away from Thor so that we can redefine it.
    class << self
      def is_thor_reserved_word?(word, type)
        return false if word == 'run'
        super
      end
    end

    desc "stacks:create VAGRANT_BOX_NAME", "create a new stack"

    method_option :name, :type => :string, :aliases => "-n", :desc => "use an alternate stack name"

    def create(box)
      name = options[:name] || box
      print "* creating stack #{name}... "
      Mason::Stacks.create(name, box)
      puts "done"
    end

    desc "stacks:destroy STACK", "destroy a stack"

    def destroy(name)
      print "* destroying stack #{name}... "
      Mason::Stacks.destroy(name)
      puts "done"
    end

    desc "stacks:up STACK", "boot a stack"

    def up(name)
      print "* booting stack #{name} (this will take a while)..."
      Mason::Stacks.up(name)
      puts "done"
    end

    desc "stacks:down STACK", "suspend a stack"

    def down(name)
      print "* stopping stack #{name}..."
      Mason::Stacks.down(name)
      puts "done"
    end

    desc "stacks:run STACK COMMAND", "run a command on a stack"

    def run(name, *args)
      Mason::Stacks.run(name, args.join(" "))
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
      when "stacks"     then Stacks
      else self
    end

    unless (args & %w( -h --help )).empty?
      klass.task_help(Thor::Shell::Basic.new, args.first)
      return
    end

    klass.start(args)
  rescue StandardError => ex
    $stderr.puts "  ! #{ex}"
    $stderr.puts "  " + ex.backtrace.join("\n  ") if ARGV.include?("--debug")
    exit 1
  end

private

  def vagrantfile
    FileUtils.mkdir_p File.expand_path("~/.mason")
    file = File.expand_path("~/.mason/Vagrantfile")
    build_vagrantfile unless File.exists?(file)
    file
  end

  def build_vagrantfile(boxes={})
    data = File.read(File.expand_path("../../../data/Vagrantfile.template", __FILE__))
    data.gsub! "BOXES", (boxes.map do |name, box|
      <<-BOX
        config.vm.define :#{name} do |config|
          config.vm.box = "#{box}"
        end
      BOX
    end.join("\n"))
    File.open(File.expand_path("~/.mason/Vagrantfile"), "w") do |file|
      file.puts data
    end
  end

end
