# Mason

Build things

	$ gem install mason

### Install buildpacks locally

	$ mason buildpacks
	* buildpacks (~/.mason/buildpacks)
	  = nodejs: https://github.com/heroku/heroku-buildpack-nodejs.git
	  = ruby: https://github.com/ddollar/heroku-buildpack-ruby.git

	$ mason buildpacks:install https://github.com/heroku/heroku-buildpack-python.git
	* installing buildpack https://github.com/heroku/heroku-buildpack-python.git

### Use buildpacks to build things

	$ mason build /tmp/app
	* detecting buildpack... done
	  = name: Ruby
	  = url: https://github.com/heroku/heroku-buildpack-ruby.git
	* compiling:
	... COMPILE OUTPUT
	* packaging... done
	  = type: dir
	  = file: /tmp/mason.out

	$ mason build /tmp/app -t dir -o /tmp/compiledapp
	* detecting buildpack... done
	  = name: Ruby
	  = url: https://github.com/heroku/heroku-buildpack-ruby.git
	* compiling...
	... COMPILE OUTPUT
	* packaging... done
	  = type: dir
	  = dir: /tmp/compiledapp

	$ mason build /tmp/app -b https://github.com/ddollar/buildpack-other.git -t tgz
	* detecting buildpack... done
	  = name: Other
	  = url: https://github.com/ddollar/buildpack-other.git
	* compiling...
	... COMPILE OUTPUT
	* packaging... done
	  = type: tgz
	  = file: /tmp/app.tgz

### Build things for other platforms using Vagrant

You will need [VirtualBox](https://www.virtualbox.org/wiki/Downloads) for Vagrant to function.

	$ gem install vagrant

	$ vagrant box add lucid64 http://files.vagrantup.com/lucid64.box

    $ mason stacks:create lucid64
    * creating stack lucid64... done

    $ mason stacks:up lucid64
    * booting stack lucid64 (this may take a while)... done

    $ mason:build /tmp/app -t tgz -o /tmp/compiled.tgz -s lucid64
    * booting stack lucid64 (this may take a while)... done
	* detecting buildpack... done
	  = name: Baz
	  = url: https://github.com/ddollar/buildpack-baz.git
	* compiling...
	... COMPILE OUTPUT
	* packaging... done
	  = type: tgz
	  = dir: /tmp/compiled.tgz
