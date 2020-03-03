[
  pod do
    metadata do
      name 'alpine-latest'
    end
    spec.containers image: 'alpine:3.9', tty: true
  end,
  pod do
    metadata do
      name 'alpine-3.9'
    end
    spec.containers image: 'alpine:3.9', tty: true
  end
]
