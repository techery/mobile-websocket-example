# Secure Mobile websocket example

This is a fork of elabs/mobile-websocket-example, showing how simple it is to integrate [Themis crypto lib](https://github.com/cossacklabs/themis) into socket-like communication and how to use it to protect stored data on your device. 

Read a blog post detailing the process with lots of sequence diagrams and step-by-step tutorial: 
https://www.cossacklabs.com/building-secure-chat

![sequence diagram with cat](https://pbs.twimg.com/media/CQOXq3HWwAAu3Ti.png)


Basically, you'll get server and 2 clients, that are communicating with each other and storing chat history in a very secure way.


## [Server](/server)

A simple websocket server written in Ruby.

To set up, run `bundle install`.

To start the server, run `ruby server.rb`


## [iOS](/ios)

Open `xcworkspace`, build and run project to start chatting. Don't forget to start server to recieve messages :)

Or follow [long guide](/ios/WebsocketExampleClient).

iOS client is written in Obj-C. Supports iOS8-10, Xcode9. 

<img src="/ios/WebsocketExampleClient/pic/socket-example.png" width="400" />


## [Android](/android)

Android client written in Java. It's very simple to run it, but if you experience problems, please, follow [this guide](https://www.cossacklabs.com/building-secure-chat).
