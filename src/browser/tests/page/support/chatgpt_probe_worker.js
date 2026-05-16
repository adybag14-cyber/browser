self.onmessage = (event) => {
  self.postMessage(`worker:${event.data}`);
};
