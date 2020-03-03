pod do
  spec.containers do
    image image_tag('latest')
    tty true
  end
  metadata name: 'alpine-latest'
end
