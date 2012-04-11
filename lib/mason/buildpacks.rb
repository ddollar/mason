require "fileutils"
require "mason"
require "mason/buildpack"
require "uri"

class Mason::Buildpacks

  def self.install(url)
    FileUtils.mkdir_p root

    Dir.chdir(root) do
      uri = URI.parse(url)
      if uri.path =~ /buildpack-(\w+)/
        name = $1
        branch = uri.fragment || master
        raise "#{name} buildpack already installed" if File.exists?(name)
        system "git clone #{url.split('#').first} #{name} >/dev/null 2>&1"
        raise "failed to clone buildpack" unless $?.exitstatus.zero?
        system "cd #{name} && git checkout #{branch}"
      else
        raise "BUILDPACK should be a url containing buildpack-NAME.git"
      end
    end
  end

  def self.uninstall(name)
    Dir.chdir(root) do
      raise "#{name} buildpack is not installed" unless File.exists?(name)
      FileUtils.rm_rf name
    end
  end

  def self.root(expand=true)
    dir = "~/.mason/buildpacks"
    expand ? File.expand_path(dir) : dir
  end

  def self.buildpacks
    @buildpacks ||= begin
      Dir[File.join(root, "*")].map do |buildpack_dir|
        Mason::Buildpack.new(buildpack_dir)
      end
    end
  end

  def self.detect(app)
    buildpacks.each do |buildpack|
      ret = buildpack.detect(app)
      return [buildpack, ret] if ret
    end
    nil
  end

end
