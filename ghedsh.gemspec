require './lib/version'

Gem::Specification.new do |s|
 s.name = 'ghedsh'
 s.version =  Ghedsh::VERSION
 s.summary ="A command line program following the philosophy of GitHub Education."
 s.description = "A command line program following the philosophy of GitHub Education. More information: https://github.com/ULL-ESIT-GRADOII-TFG/ghedsh"
 s.authors = ["Carlos de Armas", "Javier Clemente", "Casiano Rodriguez-Leon"]
 s.email = 'nookstyle@gmail.com'
 s.licenses = ['MIT']
 s.files = `git ls-files`.split($/)
 s.executables = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
 s.test_files  = s.files.grep(%r{^(test|spec|features)/})
 s.homepage = 'https://github.com/ULL-ESIT-GRADOII-TFG/ghedsh'
 s.require_paths = ['lib']
 s.required_ruby_version = '>= 2.4.0'
 s.add_dependency 'octokit', '~> 4.8'
 s.add_dependency 'require_all', '~> 1.3.2'
 s.add_development_dependency 'rake'
 s.add_development_dependency 'rspec', '~> 3.7'
 s.add_development_dependency 'bundler', '~> 1.5'
end
