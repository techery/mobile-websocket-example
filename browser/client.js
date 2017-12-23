$(document).ready(function() {
  ws = new WebSocket("ws://127.0.0.1:8080/");

  ws.onmessage = function(event) {
    $("#messages").append("<p>" + event.data + "</p>");
  };

  ws.onclose = function() {
    console.log("Socket closed");
  };

  ws.onopen = function() {
    console.log("Connected");
    // ws.send("Hello from " + navigator.userAgent);
  };

  $("#new-message").bind("submit", function(event) {
    event.preventDefault();
    ws.send($("#message-text").val());
    $("#message-text").val("");
  });
});
