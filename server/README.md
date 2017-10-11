# Server

1. To set up, run 

```
bundle install
```

Fix dependencies if needed. Sometimes for Mac it's neccessary to install eventmachine separately, like this `gem install eventmachine -v '1.0.4' -- --with-cppflags=-I/usr/local/opt/openssl/include --use-system-libraries`



2. Install rubythemis

```
gem install rubythemis
```


3. Start server

```
ruby server.rb
```

4. Start mobile clients
