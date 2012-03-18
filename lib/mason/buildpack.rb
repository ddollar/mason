require "mason"
require "tmpdir"

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

  def compile(app)
    mkchtmpdir do |cache_dir|
      compile_dir = Dir.mktmpdir
      FileUtils.rm_rf compile_dir
      FileUtils.cp_r app, compile_dir
      Dir.chdir(compile_dir) do
        IO.popen(%{ #{script("compile")} "#{compile_dir}" "#{cache_dir}" }) do |io|
          until io.eof?
            data = io.gets
            data.gsub!(/^-----> /, "  + ")
            data.gsub!(/^       /, "      ")
            data.gsub!(/^\s+$/, "")
            print data
          end
        end
      end
      compile_dir
    end
  end

private

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

