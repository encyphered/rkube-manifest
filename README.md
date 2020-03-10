rkube-manifest
==============

Ruby DSL for Kubernetes manifest

Feature
-------

* Write down Kubernetes manifest YAML with Ruby DSL. The DSL would be converted to raw-YAML.
* Value referencing from the command-line parameter or an external YAML file.
* Internal functions such as SHA256 checksum or reading another file.
* Object overriding and reuse: it reduces duplications.
* Supports built-in and user-defined function.

Supported manifests
-------------------

* Deployment
* ReplicaSet
* Pod
* Service
* CronJob
* Job
* ConfigMap
* Secret

Usage
=====

Command-line tool
-----------------

    $ rkube-manifest template [--set KEY=value] [--values VALUE_FILE] [--methods METHODS_FILE] FILENAME

If filename is `-`, it reads DSL from standard input.
Or, if filename is a directory, it reads all ruby files in the given directory.

DSL
---

Top-level definitions are camel-case and starting with lowercase.
The definition could have a block to describe detailed fields.

```
objectMeta do
  name 'alpine'
  namespace 'default'
end
```

Each definition receives optional keyword arguments as a shorthand syntax.

```
objectMeta name: 'alpine', namespace: 'default' do
  annotations({'created-by' => 'rkube-manifest'})
end
```

Each field of definition also has another shorthand syntax.
Note that this syntax is not available for top-level definition.

```
pod do
  metadata.name 'alpine'
  spec.containers image: 'alpine:latest', tty: true
end
```

When there are multiple definitions in the DSL file, only the last statement would be rendered.

### Multiple manifests in single file

If last statement of DSL is an array, it produces multiple YAMLs.

###### DSL

```
$ cat pods.rb
[
  pod do
    metadata.name 'alpine-latest'
    spec.containers image: 'alpine:latest', tty: true
  end,
  pod do
    metadata.name 'alpine-3.9'
    spec.containers image: 'alpine:3.9', tty: true
  end
]
```

###### Output

```
$ rkube-manifest pods.rb
---
apiVersion: v1
kind: Pod
metadata:
  name: alpine-latest
spec:
  containers:
  - image: alpine:latest
    tty: true
---
apiVersion: v1
kind: Pod
metadata:
  name: alpine-3.9
spec:
  containers:
  - image: alpine:3.9
    tty: true
```

### External values

#### From command-line

You can assign some values from command-line using `--set` option.
The values would be inject into single hash, `_values`.

```
$ echo 'pod do
  metadata name: "alpine-3.9", namespace: _values[:namespace]
  spec.containers image: "alpine:#{_values.dig(:image, :tag) || :latest}", tty: true
end' | rkube-manifest --set namespace=production --set image.tag=3.8 -
```

The output is:

```
---
apiVersion: v1
kind: Pod
metadata:
  name: alpine-3.9
  namespace: production
spec:
  containers:
  - image: alpine:3.8
    tty: true
```

#### From values file

Also, you can assign values massively from the YAML file using `--values` option.

```
$ cat values.yaml
namespace: production
image:
  tag: 3.9
$ echo 'pod do
  metadata name: "alpine-3.9", namespace: _values[:namespace]
  spec.containers image: "alpine:#{_values.dig(:image, :tag) || :latest}", tty: true
end' | rkube-manifest --values values.yaml -
```

The output is:

```
---
apiVersion: v1
kind: Pod
metadata:
  name: alpine-3.9
  namespace: production
spec:
  containers:
  - image: alpine:3.9
    tty: true
```

### Functions

#### Built-in functions

* to_json: Serialize argument as JSON string
* b64encode: Encode argument as base-64
* sha256: Hex checksum with SHA-256 
* md5: Hex checksum with MD5
* file: Read file as string
* manifest: Read another DSL file and render as YAML

Note that `file` and `manifest` function locates argument files from the same directory of the DSL file.
If the file not found on the DSL directory, it will try in the values file directory(-f option).

#### User-defined functions

You can import user-defined functions from file with `-m` or `--methods` option.

###### DSL

```
$ cat example/functions.rb
def image_tag(tag)
  "alpine:#{tag}"
end

$ cat example/pod_user_defined_function.rb
pod do
  spec.containers do
    image image_tag('latest')
    tty true
  end
  metadata name: 'alpine-latest'
end
```

###### Output

```
$ rkube-manifest -m example/functions.rb example/pod_user_defined_function.rb
---
apiVersion: v1
kind: Pod
metadata:
  name: alpine-latest
spec:
  containers:
  - image: alpine:latest
    tty: true
```

### Variables

You can also assign manifests to a variable and refer it.

###### DSL

```
$ cat variables.rb
vol = [
  volume(name: 'tmp', emptyDir: {}),
  volume(name: 'log', emptyDir: {}),
]

pod do
  spec do
    containers image: 'alpine:latest', tty: true do
      volumeMounts name: 'tmp', mountPath: '/tmp'
      volumeMounts name: 'log', mountPath: '/var/log'
    end
    volumes vol
  end
  metadata name: 'alpine-latest'
end
```

###### Output

```
$ rkube-manifest variables.rb
---
apiVersion: v1
kind: Pod
metadata:
  name: alpine-latest
spec:
  containers:
  - image: alpine:latest
    tty: true
    volumeMounts:
    - name: tmp
      mountPath: "/tmp"
    - name: log
      mountPath: "/var/log"
  volumes:
  - name: tmp
    emptyDir: {}
  - name: log
    emptyDir: {}
```

### Overriding

###### DSL

```
$ cat example/pod_overriding.rb
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
```

###### Output

```
$ bin/rkube-manifest example/pod_overriding.rb
---
apiVersion: v1
kind: Pod
metadata:
  name: alpine-latest
spec:
  containers:
  - image: alpine:latest
    lifecycle:
      postStart:
        exec:
        - sh
        - "-ce"
        - apk add --no-cache curl bind-tools
    tty: true

---
apiVersion: v1
kind: Pod
metadata:
  name: alpine-3.9
spec:
  containers:
  - image: alpine:3.9
    lifecycle:
      postStart:
        exec:
        - sh
        - "-ce"
        - apk add --no-cache curl bind-tools
    tty: true
```
