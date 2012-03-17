# Mason

Build things

## Instructions

### Install buildpacks locally

	$ mason buildpacks
	* buildpacks (~/.mason/buildpacks)
	  = foo: https://github.com/ddollar/buildpack-foo.git
	  = bar: https://github.com/ddollar/buildpack-bar.git

	$ mason buildpacks:install https://github.com/ddollar/buildpack-baz.git
	* adding buildpack https://github.com/ddollar/buildpack-baz.git

### Use buildpacks to build things

	$ mason build /tmp/app
	* detecting buildpack... done
	  = name: Baz
	  = url: https://github.com/ddollar/buildpack-baz.git
	* compiling:
	... COMPILE OUTPUT
	* packaging... done
	  = type: squashfs
	  = file: /tmp/app.img

	$ mason build /tmp/app -t dir -o /tmp/compiledapp
	* detecting buildpack... done
	  = name: Baz
	  = url: https://github.com/ddollar/buildpack-baz.git
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

### Use vagrant to build things for other platforms

	$ mason build /tmp/app -s cedar
	* booting vm for cedar
	...
