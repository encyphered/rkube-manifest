image_name = _values.dig(:image, :name)

pod do
  metadata do
    name 'alpine-latest'
    namespace _values.dig(:namespace)
  end
  spec.containers image: "#{image_name}:#{_values.dig(:image, :tag)}", tty: true
end
