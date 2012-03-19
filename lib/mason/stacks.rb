require "fileutils"
require "mason"

class Mason::Stacks

  def self.load_vagrant!
    require "vagrant"
    if Gem::Version.new(Vagrant::VERSION) < Gem::Version.new("1.0.1")
      raise "mason requires vagrant 1.0.1 or higher"
    end
    build_vagrantfile unless File.exists?(vagrantfile)
  end

  def self.vagrant_env(display=false)
    load_vagrant!
    ui = display ? Vagrant::UI::Basic : nil
    Vagrant::Environment.new(:vagrantfile_name => vagrantfile, :ui_class => ui)
  end

  def self.vms
    vagrant_env.vms
  end

  def self.vagrant(args)
    vagrant_env(true).cli(args)
  end

  def self.stacks
    @stacks ||= begin
      vms.inject({}) do |hash, (name, vm)|
        next(hash) if name == :default
        hash.update(name => vm.box ? vm.box.name : "")
      end
    end
  end

  def self.create(name, box)
    raise "stack already exists: #{name}" if stacks.keys.include?(name.to_sym)
    raise "vagrant box does not exist: #{box}" unless vagrant_env.boxes.map(&:name).include?(box)
    build_vagrantfile(stacks.update(name => box))
  end

  def self.destroy(name)
    raise "no such stack: #{name}" unless stacks.keys.include?(name.to_sym)
    vm = vms[name.to_sym]
    vm.halt rescue nil
    vm.destroy rescue nil
    s = stacks
    s.delete(name.to_sym)
    build_vagrantfile(s)
  end

  def self.state(name)
    raise "no such stack: #{name}" unless stacks.keys.include?(name.to_sym)
    case vms[name.to_sym].state.to_sym
      when :running then :up
      else               :down
    end
  end

  def self.up(name)
    raise "no such stack: #{name}" unless stacks.keys.include?(name.to_sym)
    return if state(name) == :up
    vms[name.to_sym].up
  end

  def self.down(name)
    raise "no such stack: #{name}" unless stacks.keys.include?(name.to_sym)
    return if state(name) == :down
    vms[name.to_sym].suspend
  end

  def self.run(name, command)
    raise "no suck stack: #{name}" unless stacks.keys.include?(name.to_sym)
    vms[name.to_sym].channel.execute(command, :error_check => false) do |type, data|
      print data
    end
  end

  def self.vagrantfile
    File.expand_path("~/.mason/Vagrantfile")
  end

  def self.vagrantfile_template
    File.expand_path("../../../data/Vagrantfile.template", __FILE__)
  end

  def self.share_dir(name)
    dir = File.expand_path("~/.mason/share/#{name}")
    FileUtils.mkdir_p dir unless File.exists?(dir)
    dir
  end

  def self.build_vagrantfile(stacks={})
    data = File.read(vagrantfile_template)
    ip_base = 3
    data.gsub! "BOXES", (stacks.map do |name, box|
      ip_base += 1
      <<-BOX
  config.vm.define :#{name} do |config|
    config.vm.box = "#{box}"
    config.vm.base_mac = "080027706AA#{ip_base}"
    config.vm.network :hostonly, "33.33.33.#{ip_base}"
    config.vm.share_folder "share", "/share", "#{share_dir(name)}"
  end
      BOX
    end.join("\n").chomp)
    File.open(vagrantfile, "w") do |file|
      file.puts data
    end
  end

end
