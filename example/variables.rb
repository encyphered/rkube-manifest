vol = [
    volume(name: 'tmp', emptyDir: {}),
    volume(name: 'log', emptyDir: {}),
]

pod do
  spec do
    containers do
      image 'alpine:latest'
      tty true
    end
    volumes vol
  end
  metadata name: 'alpine-latest'
end
