require 'base'

class CliTest < TestBase
  include KubeManifest::CLI::Utils

  def test_symbolize_keys
    result = symbolize_keys({'a' => 1, 'b' => {'c' => 2}})
    expect = {:a => 1, :b => {:c => 2}}
    assert_equal expect, result
  end

  def test_transform_to_hash
    result = transform_to_hash(['foo.bar=1==2'])
    expect = {'foo' => {'bar' => '1==2'}}
    assert_equal expect, result
  end

  def test_merge_hash_recursive
    a = {:a => 1, :b => [2, 3], :c => "d", :e => {:f => "g"}}
    b = {:a => 2, :b => [3], :e => {:h => "i"}}

    result = merge_hash_recursive(a, b)
    expect = {:a => 2, :b => [3], :c => "d", :e => {:f => "g", :h => "i"}}
    assert_equal expect, result
  end

  def test_values_override
    filename = File.join(__dir__, '../example/pod_with_values.rb')
    options = {values: ['image.tag=3.9']}
    cli = KubeManifest::CLI::Exec.new(filenames: [filename], options: options)
    manifest = cli.run.map{ |m| m.as_hash }

    expect_dir = expand_dir(File.join(__dir__, '../example'))
    assert_equal expect_dir, cli.cwd
    assert_equal 'production', manifest.dig(0, :metadata, :namespace)
    assert_equal 'alpine:3.9', manifest.dig(0, :spec, :containers, 0, :image)
  end

  def test_values_override_file
    filename = File.join(__dir__, '../example/pod_with_values.rb')
    options = {values_file: File.join(__dir__, '../example/values/alpine-3.9.yaml')}
    cli = KubeManifest::CLI::Exec.new(filenames: [filename], options: options)
    manifest = cli.run.map{ |m| m.as_hash }

    expect_dir = expand_dir(options[:values_file])
    assert_equal expect_dir, cli.cwd
    assert_equal 'production', manifest.dig(0, :metadata, :namespace)
    assert_equal 'alpine:3.9', manifest.dig(0, :spec, :containers, 0, :image)
  end
end