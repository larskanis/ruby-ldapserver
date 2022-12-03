# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ldap/server/version'

Gem::Specification.new do |s|
  s.name = %q{ruby-ldapserver}
  s.version = LDAP::Server::VERSION

  s.authors = ["Brian Candler", "Florian Dejonckheere", "Lars Kanis"]
  s.description = %q{ruby-ldapserver is a lightweight, pure-Ruby skeleton for implementing LDAP server applications.}
  s.email = ["B.Candler@pobox.com", "florian@floriandejonckheere.be", "lars@greiz-reinsdorf.de"]
  s.files = `git ls-files`.split($/)
  s.homepage = %q{https://github.com/larskanis/ruby-ldapserver}
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.summary = %q{A pure-Ruby framework for building LDAP servers}
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  s.required_ruby_version = '>= 2.3'

  s.add_development_dependency 'bundler', '>= 1.3', '< 3.0'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'net-ldap', '~> 0.10'
  s.add_development_dependency 'rspec', '~> 3.1'
  s.add_development_dependency 'test-unit', '~> 3.0'
end
