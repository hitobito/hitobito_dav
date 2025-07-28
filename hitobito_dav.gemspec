$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your wagon's version:
require "hitobito_dav/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  # rubocop:disable Style/SingleSpaceBeforeFirstArg
  s.name = "hitobito_dav"
  s.version = HitobitoDav::VERSION
  s.authors = ["Matthias Viehweger"]
  s.email = ["viehweger@puzzle.ch"]
  s.homepage = "https://alpenverein.de"
  s.summary = "Deutscher Alpenverein"
  s.description = "Organization structure and specific features for DAV"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile"]
  s.add_dependency "hitobito_youth"
  s.add_dependency "net-ssh", "~> 7.0.0.beta1" # TODO: remove once net-sftp 3 updates ssh 7
  s.add_dependency "net-sftp"
  # rubocop:enable Style/SingleSpaceBeforeFirstArg
end
