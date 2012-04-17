require "mason"
require "tmpdir"
require "yaml"
require "foreman/engine"

class Mason::Buildpack

  attr_reader :dir, :name, :url

  def initialize(dir)
    @dir = dir
    Dir.chdir(@dir) do
      @name = File.basename(@dir)
      @url  = %x{ git config remote.origin.url }.chomp
    end
  end

  def <=>(other)
    self.name <=> other.name
  end

  def detect(app)
    mkchtmpdir do
      output = %x{ #{script("detect")} "#{app}" }
      $?.exitstatus.zero? ? output.chomp : nil
    end
  end

  def compile(app, env_file=nil)
    cache_dir = "#{app}/.git/cache"
    puts "  caching in #{cache_dir}"
    compile_dir = Dir.mktmpdir
    FileUtils.rm_rf compile_dir
    FileUtils.cp_r app, compile_dir
    FileUtils.mkdir_p cache_dir
    Dir.chdir(compile_dir) do
      IO.popen(%{ #{script("compile")} "#{compile_dir}" "#{cache_dir}" }) do |io|
        until io.eof?
          data = io.gets
          data.gsub!(/^-----> /, "  + ")
          data.gsub!(/^       /, "      ")
          data.gsub!(/^\s+\!\s+$/, "")
          data.gsub!(/^\s+\!\s+/, "  ! ")
          data.gsub!(/^\s+$/, "")
          print data
        end
      end
      raise "compile failed" unless $?.exitstatus.zero?
    end
    release = YAML.load(`#{script('release')}`)
    write_env(compile_dir, env_file, release)
    compile_dir
  end

private

  def write_env(compile_dir, env_file, release)
    # TODO: expose this in foreman
    env = Foreman::Engine.read_environment(env_file)
    config = release["config_vars"].merge(env)

    File.open(File.join(compile_dir, ".env"), "w") do |f|
      f.puts config.map{|k, v| "#{k}=#{v}"}.join("\n")
    end
  end

  def mkchtmpdir
    ret = nil
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        ret = yield(dir)
      end
    end
    ret
  end

  def script(name)
    File.join(dir, "bin", name)
  end
end

