pod do
  metadata do
    name 'alpine-latest'
    namespace _values.dig(:namespace)
  end
  spec.containers image: "#{_values.dig(:image, :name)}:#{_values.dig(:image, :tag)}", tty: true
end
