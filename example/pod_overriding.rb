alpine = container do
  tty true
  lifecycle.postStart.exec ['sh', '-ce', 'apk add --no-cache curl bind-tools']
end

[
  pod do
    metadata.name 'alpine-latest'
    spec.containers(alpine) { image 'alpine:latest' }
  end,
  pod do
    metadata.name 'alpine-3.9'
    spec.containers(alpine) { image 'alpine:3.9' }
  end
]
