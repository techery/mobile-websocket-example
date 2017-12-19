# Server

1. To set up, run

```console
bundle install
```

Fix dependencies if needed. Sometimes for Mac it's neccessary to install eventmachine separately, like this

```console
gem install eventmachine -v '1.0.4' -- --with-cppflags=-I/usr/local/opt/openssl/include --use-system-libraries
```

2. Install rubythemis

```console
gem install rubythemis
```


3. Start server

```console
ruby server.rb
```

4. Start mobile clients
