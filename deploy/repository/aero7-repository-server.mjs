import fs from "node:fs";
import http from "node:http";
import path from "node:path";

const root = path.resolve(process.env.AERO7_REPOSITORY_ROOT || "/home/admin/aero7-site/storage/pacman-root");
const port = Number(process.env.AERO7_REPOSITORY_PORT || 2587);
const host = process.env.AERO7_REPOSITORY_HOST || "127.0.0.1";

const contentTypes = new Map([
  [".css", "text/css; charset=utf-8"],
  [".db", "application/octet-stream"],
  [".gz", "application/gzip"],
  [".html", "text/html; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".sig", "application/pgp-signature"],
  [".zst", "application/zstd"],
]);

function sendError(response, status, message) {
  response.writeHead(status, {
    "Content-Type": "text/plain; charset=utf-8",
    "Cache-Control": "no-store",
    "X-Content-Type-Options": "nosniff",
  });
  response.end(`${message}\n`);
}

function requestPath(request) {
  let pathname;
  try {
    pathname = decodeURIComponent(new URL(request.url, "http://repository.invalid").pathname);
  } catch {
    return null;
  }
  if (!pathname.startsWith("/repo/")) return null;
  const resolved = path.resolve(root, `.${pathname}`);
  if (resolved !== root && !resolved.startsWith(`${root}${path.sep}`)) return null;
  return resolved;
}

function cacheControl(filename) {
  if (filename.includes(`${path.sep}status${path.sep}`)) return "no-store";
  if (/\.pkg\.tar\.zst(?:\.sig)?$/.test(filename)) return "public, max-age=31536000, immutable";
  return "public, max-age=60, must-revalidate";
}

const server = http.createServer((request, response) => {
  if (request.method !== "GET" && request.method !== "HEAD") {
    response.setHeader("Allow", "GET, HEAD");
    return sendError(response, 405, "Method not allowed");
  }

  let filename = requestPath(request);
  if (!filename) return sendError(response, 404, "Not found");
  try {
    const initial = fs.statSync(filename);
    if (initial.isDirectory()) filename = path.join(filename, "index.html");
  } catch {
    return sendError(response, 404, "Not found");
  }

  let stat;
  try {
    stat = fs.statSync(filename);
    if (!stat.isFile()) return sendError(response, 404, "Not found");
  } catch {
    return sendError(response, 404, "Not found");
  }

  const headers = {
    "Accept-Ranges": "bytes",
    "Cache-Control": cacheControl(filename),
    "Content-Type": contentTypes.get(path.extname(filename)) || "application/octet-stream",
    "Last-Modified": stat.mtime.toUTCString(),
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "SAMEORIGIN",
  };

  let start = 0;
  let end = stat.size - 1;
  let status = 200;
  const range = request.headers.range;
  if (range) {
    const match = /^bytes=(\d*)-(\d*)$/.exec(range);
    if (!match) return sendError(response, 416, "Invalid range");
    if (match[1]) start = Number(match[1]);
    if (match[2]) end = Number(match[2]);
    if (!match[1] && match[2]) {
      const suffix = Number(match[2]);
      start = Math.max(0, stat.size - suffix);
      end = stat.size - 1;
    }
    if (!Number.isSafeInteger(start) || !Number.isSafeInteger(end) || start > end || end >= stat.size) {
      response.setHeader("Content-Range", `bytes */${stat.size}`);
      return sendError(response, 416, "Range not satisfiable");
    }
    status = 206;
    headers["Content-Range"] = `bytes ${start}-${end}/${stat.size}`;
  }
  headers["Content-Length"] = String(end - start + 1);
  response.writeHead(status, headers);
  if (request.method === "HEAD") return response.end();
  fs.createReadStream(filename, { start, end }).on("error", () => response.destroy()).pipe(response);
});

server.listen(port, host, () => {
  console.log(`Aero7 repository server listening on http://${host}:${port} from ${root}`);
});
