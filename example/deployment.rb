deployment do
  spec replicas: 2 do
    selector.matchLabels app: 'nginx'

    template do
      metadata.labels app: 'nginx'
      spec do
        containers name: 'nginx', image: 'nginx:latest' do
          ports containerPort: 80, protocol: 'TCP'
        end
      end
    end

    strategy type: 'RollingUpdate',
             rollingUpdate: {
                 maxSurge: '25%',
                 maxUnavailable: '25%'
             }
  end

  metadata name: 'nginx'
end
