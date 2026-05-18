self.onmessage = (event) => {
  if (event.data === "probe-runtime") {
    self.postMessage({
      chrome: typeof self.chrome,
      chromeCsi: typeof self.chrome?.csi,
      chromeLoadTimes: typeof chrome?.loadTimes,
      navigator: typeof self.navigator,
      performanceNow: typeof performance?.now,
      caches: typeof caches?.open,
      messagePorts: Array.isArray(event.ports) ? event.ports.length : -1,
    });
    return;
  }
  self.postMessage(`worker:${event.data}`);
};
