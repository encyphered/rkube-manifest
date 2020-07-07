Gem::Specification.new do |spec|
  spec.name = 'rkube-manifest'
  spec.version = '0.0.3'
  spec.author = 'Geunwoo Shin'
  spec.email = 'encyphered@gmail.com'
  spec.homepage = 'https://github.com/encyphered/rkube-manifest'
  spec.licenses = ['MIT']
  spec.summary = 'Simple DSL for describe Kubernetes manifest'
  spec.files = Dir['lib/**/*'].append('bin/rkube-manifest').flatten
  spec.required_ruby_version = '>= 2.5.0'
  spec.executables = ['rkube-manifest']
end
