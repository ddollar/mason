require "fileutils"
require "mason"

class Mason::Buildpack

  def self.list
    puts "* buildpacks (#{buildpacks_pretty_root})"
    buildpacks.keys.sort.each do |name|
      puts "  = #{name}: #{buildpacks[name]}"
    end
    puts "  - no buildpacks installed, use buildpacks:add" if buildpacks.length.zero?
  end

  def self.install(url)
    FileUtils.mkdir_p buildpacks_root
    Dir.chdir(buildpacks_root) do
      if url =~ /buildpack-(\w+)/
        name = $1
        raise "#{name} buildpack already installed" if File.exists?(name)
        system "git clone #{url} #{name}"
      else
        raise "BUILDPACK should be a url containing buildpack-NAME.git"
      end
    end
  end

  def self.uninstall(name)
    Dir.chdir(buildpacks_root) do
      raise "#{name} buildpack is not installed" unless File.exists?(name)
      FileUtils.rm_rf name
    end
  end

private

  def self.buildpacks
    @buildpacks ||= begin
      Dir[File.join(buildpacks_root, "*")].inject({}) do |hash, buildpack|
        Dir.chdir(buildpack) do
          name = File.basename(buildpack)
          url  = %x{ git config remote.origin.url }.chomp
          hash.update(name => url)
        end
      end
    end
  end

  def self.buildpacks_pretty_root
    "~/.mason/buildpacks"
  end

  def self.buildpacks_root
    File.expand_path(buildpacks_pretty_root)
  end

end
