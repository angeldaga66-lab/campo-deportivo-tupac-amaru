const CACHE='tupac-amaru-app-v1';
const SHELL=['./','./index.html','./manifest.json','./icon-192.png','./icon-512.png'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(CACHE).then(c=>c.addAll(SHELL)));self.skipWaiting();});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))));self.clients.claim();});
self.addEventListener('fetch',e=>{
 const r=e.request;
 if(r.method!=='GET'||new URL(r.url).origin!==self.location.origin)return;
 if(r.mode==='navigate'){
   e.respondWith(fetch(r).then(res=>{caches.open(CACHE).then(c=>c.put('./index.html',res.clone()));return res;}).catch(()=>caches.match('./index.html')));
 }else{
   e.respondWith(caches.match(r).then(c=>c||fetch(r).then(res=>{caches.open(CACHE).then(x=>x.put(r,res.clone()));return res;})));
 }
});