self.onconnect = (event) => {
  const port = event.ports[0];
  if (typeof port.start === "function") {
    port.start();
  }
  port.onmessage = (message) => {
    port.postMessage(`shared:${message.data}`);
  };
};
