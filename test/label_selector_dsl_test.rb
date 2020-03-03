require 'base'

class LabelSelectorDslTest < TestBase
  def test_label_selector
    manifest = KubeManifest.LabelSelector do
      matchLabels app: 'web'
      matchExpressions key: 'environment', operator: 'In', values: ['production']
    end.as_hash

    assert_include manifest, :matchLabels
    assert_include manifest, :matchExpressions
  end

  def test_match_expressions_empty
    manifest = KubeManifest.LabelSelector do
      matchLabels app: 'web'
    end.as_hash

    assert_include manifest, :matchLabels
    assert_not_include manifest, :matchExpressions
  end

  def test_match_labels_empty
    manifest = KubeManifest.LabelSelector do
      matchExpressions key: 'environment', operator: 'In', values: ['production']
    end.as_hash

    assert_not_include manifest, :matchLabels
    assert_include manifest, :matchExpressions
  end
end