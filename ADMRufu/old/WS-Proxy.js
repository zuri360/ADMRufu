/*
* Proxy Bridge (base PANCHO7532 - P7COMUnications LLC)
* FIX-SSH: responde 101 cuando llegan los headers y descarta todo el payload
*          HTTP hasta ver "SSH-". Asi OpenSSH no corta con
*          "Invalid SSH identification string". Mismos parametros:
*          -dhost 127.0.0.1 -dport 22 -mport 80
*/
const net = require('net');
const a = process.argv;
const opt = (n, d) => { const i = a.indexOf(n); return i > -1 && a[i+1] ? a[i+1] : d; };
const DHOST = opt('-dhost', '127.0.0.1');
const DPORT = +opt('-dport', 22);
const MPORT = +opt('-mport', 80);
const RESP = 'HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n';

net.createServer(c => {
  let buf = Buffer.alloc(0), ssh = null, ready = false;
  const end = () => { c.destroy(); if (ssh) ssh.destroy(); };
  const conectar = () => {
    ssh = net.connect(DPORT, DHOST);
    ssh.setNoDelay(true);
    ssh.pipe(c);
    ssh.on('error', end).on('close', end);
  };
  c.setNoDelay(true);
  c.on('error', end).on('close', end);
  c.on('data', d => {
    if (ready) return ssh.write(d);
    buf = Buffer.concat([buf, d]);
    if (!ssh) {
      if (buf.indexOf('SSH-') === 0) conectar();
      else if (buf.indexOf('\r\n\r\n') > -1) { c.write(RESP); conectar(); }
    }
    if (ssh) {
      const i = buf.indexOf('SSH-');
      if (i > -1) { ssh.write(buf.subarray(i)); buf = null; ready = true; return; }
    }
    if (buf.length > 65536) end();
  });
}).listen(MPORT, () => console.log(`[INFO] WS-Proxy :${MPORT} -> ${DHOST}:${DPORT}`));
