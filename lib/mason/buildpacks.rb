require "fileutils"
require "mason"
require "mason/buildpack"
require "uri"
require "digest/sha1"

class Mason::Buildpacks

  def self.install(url, ad_hoc=false)
    root_dir = ad_hoc ? ad_hoc_root : root
    FileUtils.mkdir_p root_dir

    Dir.chdir(root_dir) do
      uri = URI.parse(url)
      if uri.path =~ /buildpack-(\w+)/
        name = $1
        name += "-#{Digest::SHA1.hexdigest(url).to_s[0 .. 8]}" if ad_hoc
        branch = uri.fragment || "master"
        if File.exists?(name)
          # Can't do a fetch here as it won't update local branches
          system "cd #{name} && git checkout -b master && git pull"
          raise "failed to update buildpack checkout" unless $?.exitstatus.zero?
        else
          system "git clone #{url.split('#').first} #{name} >/dev/null 2>&1"
          raise "failed to clone buildpack" unless $?.exitstatus.zero?
        end
        system "cd #{name} && git checkout #{branch} 2> /dev/null"
        raise "failed to check out branch #{branch}" unless $?.exitstatus.zero?
        File.expand_path(root_dir + "/" + name)
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

  def self.root(ad_hoc=false, expand=true)
    dir = "~/.mason/buildpacks"
    expand ? File.expand_path(dir) : dir
  end

  def self.ad_hoc_root(expand=true)
    dir = "~/.mason/buildpacks-ad-hoc"
    expand ? File.expand_path(dir) : dir
  end

  def self.buildpacks
    @buildpacks ||= begin
      Dir[File.join(root, "*")].map do |buildpack_dir|
        Mason::Buildpack.new(buildpack_dir)
      end
    end
  end

  def self.detect(app, url = ENV["BUILDPACK_URL"])
    if url
      puts "Using $BUILDPACK_URL: #{url}"
      buildpack_dir = install(url, true)
      return Mason::Buildpack.new(buildpack_dir)
    else
      buildpacks.each do |buildpack|
        ret = buildpack.detect(app)
        return [buildpack, ret] if ret
      end
    end
    nil
  end

end
