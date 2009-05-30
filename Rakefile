require 'rubygems'
require 'rake/gempackagetask'
PKG_NAME = "rlayout"
PKG_VERSION = "0.5.3"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"
PKG_FILES = FileList[
  '[A-Z]*',
  'lib/**/*',
  'example/**/*'
]
spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "improve rails layout such as simplifying content_for usage and let erb file can determine layout"
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.require_path = 'lib'
  s.homepage = %q{http://rlayout.rubyforge.org/}
  s.rubyforge_project = 'Rails Layout Extension'
  s.has_rdoc = false
  s.authors = ["Leon Li"]
  s.email = "scorpio_leon@hotmail.com"
  s.files = PKG_FILES
  s.description = <<-EOF
    improve rails layout such as simplifying content_for usage and let erb file can determine layout
  EOF
end
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end
