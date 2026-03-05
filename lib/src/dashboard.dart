/// The single-page HTML dashboard served by [PreviewServer].
///
/// This file contains the complete HTML, CSS, and JavaScript for the
/// bloc_preview web UI.  It is embedded as a raw string constant so that
/// no external assets are required at runtime.
///
/// ## Dashboard features
///
/// * **Timeline** — live event feed with performance timing.
/// * **State diff** — highlights exactly which fields changed.
/// * **Snapshot export** — copy any state as JSON to clipboard.
/// * **Lifecycle map** — horizontal bars showing bloc lifetimes.
/// * **Frequency monitor** — detects event storms per bloc.
/// * **State size tracker** — shows serialised state size over time.
const String dashboardHtml = r'''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>bloc_preview</title>
<style>
  :root {
    --bg0: #0d1117;
    --bg1: #161b22;
    --bg2: #21262d;
    --bg3: #30363d;
    --border: #30363d;
    --tx0: #e6edf3;
    --tx1: #8b949e;
    --tx2: #484f58;
    --accent: #58a6ff;
    --accent-s: #58a6ff22;
    --green: #3fb950;
    --green-s: #3fb95022;
    --yellow: #d29922;
    --yellow-s: #d2992222;
    --red: #f85149;
    --red-s: #f8514922;
    --purple: #bc8cff;
    --cyan: #76e3ea;
    --orange: #f0883e;
    --r: 6px;
    --mono: 'SF Mono','Cascadia Code','Fira Code',Consolas,monospace;
    --sans: -apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;
  }
  *{margin:0;padding:0;box-sizing:border-box}
  body{font-family:var(--sans);background:var(--bg0);color:var(--tx0);height:100vh;display:flex;flex-direction:column;overflow:hidden}

  /* ── Header ── */
  header{display:flex;align-items:center;gap:12px;padding:0 16px;height:48px;background:var(--bg1);border-bottom:1px solid var(--border);flex-shrink:0}
  .logo{font-weight:700;font-size:14px;color:var(--accent);letter-spacing:-0.3px}
  .dot{width:8px;height:8px;border-radius:50%;background:var(--red);transition:background .3s}
  .dot.on{background:var(--green)}
  .tabs{display:flex;gap:2px;margin-left:24px}
  .tab{padding:6px 14px;font-size:12px;color:var(--tx1);cursor:pointer;border-radius:var(--r) var(--r) 0 0;transition:all .12s;border:1px solid transparent;border-bottom:none}
  .tab:hover{color:var(--tx0);background:var(--bg2)}
  .tab.active{color:var(--accent);background:var(--bg0);border-color:var(--border)}
  .hdr-stats{margin-left:auto;display:flex;gap:16px;font-size:12px;color:var(--tx1)}
  .hdr-stats strong{color:var(--tx0);font-weight:600}

  /* ── Layout ── */
  .workspace{flex:1;display:flex;overflow:hidden}
  .page{display:none;flex:1;overflow:hidden}
  .page.visible{display:flex}

  /* ── Panel: Bloc list ── */
  .p-blocs{width:220px;min-width:120px;background:var(--bg1);border-right:1px solid var(--border);display:flex;flex-direction:column;flex-shrink:0}
  .p-title{padding:10px 14px;font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.5px;color:var(--tx1);border-bottom:1px solid var(--border)}
  .bloc-list{flex:1;overflow-y:auto;padding:4px}
  .bloc-entry{display:flex;align-items:center;justify-content:space-between;padding:7px 10px;border-radius:var(--r);cursor:pointer;font-size:12px;font-family:var(--mono);color:var(--tx0);transition:background .12s}
  .bloc-entry:hover{background:var(--bg2)}
  .bloc-entry.sel{background:var(--accent-s);color:var(--accent)}
  .bloc-entry .cnt{font-size:10px;padding:1px 6px;border-radius:10px;background:var(--bg2);color:var(--tx1);font-family:var(--sans)}
  .bloc-entry.sel .cnt{background:var(--accent-s);color:var(--accent)}
  .bloc-freq{font-size:9px;color:var(--tx2);margin-left:4px}
  .bloc-freq.warn{color:var(--red);font-weight:700}

  /* ── Drag ── */
  .drag{width:4px;cursor:col-resize;flex-shrink:0;background:transparent;transition:background .15s}
  .drag:hover,.drag.on{background:var(--accent);opacity:.4}

  /* ── Toolbar ── */
  .toolbar{display:flex;align-items:center;gap:8px;padding:8px 12px;border-bottom:1px solid var(--border);flex-shrink:0}
  .toolbar input{background:var(--bg2);border:1px solid var(--border);color:var(--tx0);padding:5px 10px;border-radius:var(--r);font-size:12px;outline:none;width:200px;font-family:var(--sans)}
  .toolbar input:focus{border-color:var(--accent)}
  .toolbar input::placeholder{color:var(--tx2)}
  .btn{background:var(--bg2);border:1px solid var(--border);color:var(--tx1);padding:5px 12px;border-radius:var(--r);cursor:pointer;font-size:11px;font-family:var(--sans);transition:all .12s}
  .btn:hover{color:var(--tx0);background:var(--bg3)}
  .btn-accent{background:var(--accent-s);color:var(--accent);border-color:var(--accent)}
  .btn-accent:hover{background:var(--accent);color:#fff}

  /* ── Timeline ── */
  .feed{flex:1;overflow-y:auto;padding:4px 8px}
  .ev{display:flex;align-items:center;gap:8px;padding:5px 8px;border-radius:var(--r);cursor:pointer;font-size:12px;transition:background .1s;border-left:3px solid transparent}
  .ev:hover{background:var(--bg1)}
  .ev.act{background:var(--bg1);border-left-color:var(--accent)}
  .ev-t{font-size:10px;font-family:var(--mono);color:var(--tx2);min-width:60px;flex-shrink:0}
  .ev-tag{font-size:9px;font-weight:700;text-transform:uppercase;letter-spacing:.4px;padding:2px 8px;border-radius:10px;min-width:72px;text-align:center;flex-shrink:0}
  .ev-tag.create{background:var(--green-s);color:var(--green)}
  .ev-tag.transition{background:var(--accent-s);color:var(--accent)}
  .ev-tag.change{background:var(--yellow-s);color:var(--yellow)}
  .ev-tag.close{background:var(--red-s);color:var(--red)}
  .ev-tag.error{background:var(--red-s);color:var(--red);font-style:italic}
  .ev-bloc{font-family:var(--mono);font-weight:500;color:var(--purple);flex-shrink:0}
  .ev-ms{font-size:10px;color:var(--tx2);min-width:45px;text-align:right;font-family:var(--mono)}
  .ev-ms.slow{color:var(--red);font-weight:700}
  .ev-sum{color:var(--tx2);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;margin-left:auto;max-width:180px;font-size:11px}

  /* ── Detail panel ── */
  .p-detail{width:400px;min-width:200px;max-width:800px;background:var(--bg1);border-left:1px solid var(--border);overflow-y:auto;padding:16px;display:none;flex-shrink:0}
  .p-detail.open{display:block}
  .d-head{font-size:13px;font-weight:600;color:var(--accent);padding-bottom:10px;margin-bottom:12px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
  .d-label{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;color:var(--tx2);margin:14px 0 6px}
  .d-meta{display:flex;gap:16px;margin-bottom:10px;font-size:11px;color:var(--tx1)}
  .d-meta .val{color:var(--tx0);font-weight:600}
  .d-meta .warn{color:var(--red)}

  /* ── Diff ── */
  .diff-row{font-family:var(--mono);font-size:12px;padding:2px 6px;border-radius:3px;margin:1px 0}
  .diff-add{background:#3fb95015;color:var(--green)}
  .diff-rem{background:#f8514915;color:var(--red)}
  .diff-mod{background:#d2992215;color:var(--yellow)}
  .diff-same{color:var(--tx2)}

  /* ── Tree ── */
  .tree{font-size:12px;font-family:var(--mono);line-height:1.6;word-break:break-word}
  .t-key{color:var(--accent)}.t-str{color:var(--green);word-break:break-all}.t-num{color:var(--orange)}.t-bool{color:var(--yellow)}.t-null{color:var(--tx2);font-style:italic}.t-enum{color:var(--purple);font-weight:600}
  .t-type{color:var(--yellow);font-weight:700;font-size:11px;background:var(--yellow-s);padding:1px 6px;border-radius:4px}
  .t-grp{border-left:2px solid var(--border);margin-left:4px;margin-top:2px}
  .t-row{padding:1px 0}.t-row:hover{background:var(--bg0);border-radius:3px}
  .t-fold{cursor:pointer;user-select:none}.t-fold::before{content:'\25BC ';font-size:8px;color:var(--tx2)}.t-fold.shut::before{content:'\25B6 '}.t-kids.collapsed{display:none}

  /* ── Lifecycle page ── */
  .lc-container{flex:1;padding:16px;overflow:auto}
  .lc-row{display:flex;align-items:center;gap:10px;margin-bottom:6px;font-size:12px}
  .lc-name{min-width:150px;font-family:var(--mono);color:var(--purple);text-align:right;flex-shrink:0}
  .lc-bar-wrap{flex:1;height:22px;background:var(--bg2);border-radius:var(--r);position:relative;overflow:hidden}
  .lc-bar{position:absolute;height:100%;border-radius:var(--r);min-width:4px}
  .lc-bar.alive{background:var(--green-s);border:1px solid var(--green)}
  .lc-bar.dead{background:var(--red-s);border:1px solid var(--red)}
  .lc-time{font-size:10px;color:var(--tx2);font-family:var(--mono);min-width:60px}
  .lc-legend{display:flex;gap:20px;margin-bottom:16px;font-size:11px;color:var(--tx1)}
  .lc-legend-dot{display:inline-block;width:10px;height:10px;border-radius:3px;margin-right:4px;vertical-align:middle}

  /* ── Analytics page ── */
  .an-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px;padding:16px;overflow:auto;flex:1}
  .an-card{background:var(--bg1);border:1px solid var(--border);border-radius:var(--r);padding:16px;overflow:auto}
  .an-card h3{font-size:13px;color:var(--accent);margin-bottom:12px;padding-bottom:8px;border-bottom:1px solid var(--border)}
  .an-table{width:100%;font-size:12px;border-collapse:collapse}
  .an-table th{text-align:left;font-size:10px;text-transform:uppercase;letter-spacing:.5px;color:var(--tx2);padding:6px 8px;border-bottom:1px solid var(--border)}
  .an-table td{padding:6px 8px;border-bottom:1px solid var(--bg2);font-family:var(--mono)}
  .an-table .nm{color:var(--purple)}
  .an-table .hi{color:var(--red);font-weight:700}
  .bar-tiny{display:inline-block;height:8px;border-radius:4px;background:var(--accent);vertical-align:middle;margin-left:6px}

  .placeholder{display:flex;align-items:center;justify-content:center;height:100%;color:var(--tx2);font-size:13px}

  /* ── Toast ── */
  .toast{position:fixed;bottom:24px;right:24px;background:var(--green);color:#fff;padding:8px 16px;border-radius:var(--r);font-size:12px;font-weight:600;opacity:0;transition:opacity .3s;pointer-events:none;z-index:999}
  .toast.show{opacity:1}
</style>
</head>
<body>

<header>
  <div class="dot" id="dot"></div>
  <span class="logo">bloc_preview</span>
  <div class="tabs">
    <div class="tab active" onclick="switchTab('timeline')">Timeline</div>
    <div class="tab" onclick="switchTab('lifecycle')">Lifecycle</div>
    <div class="tab" onclick="switchTab('analytics')">Analytics</div>
  </div>
  <div class="hdr-stats">
    <span>Blocs: <strong id="hB">0</strong></span>
    <span>Events: <strong id="hE">0</strong></span>
  </div>
</header>

<div class="workspace">
  <!-- Bloc list (shared) -->
  <div class="p-blocs" id="pBlocs">
    <div class="p-title">Active blocs</div>
    <div class="bloc-list" id="bList"></div>
  </div>
  <div class="drag" id="dBlocs"></div>

  <!-- PAGE: Timeline -->
  <div class="page visible" id="pg-timeline">
    <div style="flex:1;display:flex;flex-direction:column;min-width:200px;overflow:hidden">
      <div class="toolbar">
        <input id="searchBox" type="text" placeholder="Filter events...">
        <button class="btn" id="btnClear">Clear</button>
      </div>
      <div class="feed" id="feed"><div class="placeholder">Waiting for events...</div></div>
    </div>
    <div class="drag" id="dDetail"></div>
    <div class="p-detail" id="pDetail"></div>
  </div>

  <!-- PAGE: Lifecycle -->
  <div class="page" id="pg-lifecycle">
    <div class="lc-container" id="lcContainer">
      <div class="placeholder">No lifecycle data yet</div>
    </div>
  </div>

  <!-- PAGE: Analytics -->
  <div class="page" id="pg-analytics">
    <div class="an-grid" id="anGrid">
      <div class="an-card">
        <h3>Event Frequency</h3>
        <table class="an-table" id="freqTable">
          <thead><tr><th>Bloc</th><th>Events</th><th>Rate (ev/s)</th><th></th></tr></thead>
          <tbody></tbody>
        </table>
      </div>
      <div class="an-card">
        <h3>State Size</h3>
        <table class="an-table" id="sizeTable">
          <thead><tr><th>Bloc</th><th>Size (bytes)</th><th></th></tr></thead>
          <tbody></tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<div class="toast" id="toast">Copied to clipboard</div>

<script>
// ── State ──
let events=[], states={}, lifecycles=[], frequencies={}, stateSizes={};
let pickedEv=null, pickedBloc=null, curTab='timeline';
let ws;
const $=id=>document.getElementById(id);

// ── Tabs ──
function switchTab(t){
  curTab=t;
  document.querySelectorAll('.tab').forEach(el=>el.classList.toggle('active',el.textContent.trim().toLowerCase()===t));
  document.querySelectorAll('.page').forEach(el=>el.classList.toggle('visible',el.id==='pg-'+t));
  render();
}

// ── Drag ──
function setupDrag(hId,pFn,dir){
  const h=$(hId);let o,s;
  const mv=e=>{const d=e.clientX-o;const n=dir==='left'?s+d:s-d;pFn().style.width=Math.max(120,Math.min(n,800))+'px'};
  const up=()=>{h.classList.remove('on');document.body.style.cursor='';document.body.style.userSelect='';document.removeEventListener('mousemove',mv);document.removeEventListener('mouseup',up)};
  h.addEventListener('mousedown',e=>{e.preventDefault();o=e.clientX;s=pFn().offsetWidth;h.classList.add('on');document.body.style.cursor='col-resize';document.body.style.userSelect='none';document.addEventListener('mousemove',mv);document.addEventListener('mouseup',up)});
}
setupDrag('dBlocs',()=>$('pBlocs'),'left');
setupDrag('dDetail',()=>$('pDetail'),'right');

// ── WebSocket ──
function connect(){
  ws=new WebSocket('ws://'+location.host);
  ws.onopen=()=>$('dot').classList.add('on');
  ws.onclose=()=>{$('dot').classList.remove('on');setTimeout(connect,2000)};
  ws.onmessage=msg=>{
    const d=JSON.parse(msg.data);
    if(d.type==='snapshot'){
      states=d.states||{};events=d.log||[];lifecycles=d.lifecycles||[];frequencies=d.frequencies||{};stateSizes=d.stateSizes||{};
    } else if(d.type==='event'){
      const e=d.data;events.push(e);
      if(e.state!==undefined&&e.type!=='close'){states[e.bloc]=e.state}
      else if(e.type==='close'){delete states[e.bloc]}
      if(e.frequency!==undefined) frequencies[e.bloc]=e.frequency;
      if(e.stateSize!==undefined) stateSizes[e.bloc]=e.stateSize;
      // Update lifecycle
      if(e.type==='create') lifecycles.push({bloc:e.bloc,created:e.timestamp,closed:null});
      if(e.type==='close'){for(let i=lifecycles.length-1;i>=0;i--){if(lifecycles[i].bloc===e.bloc&&!lifecycles[i].closed){lifecycles[i].closed=e.timestamp;break}}}
    }
    render();
  };
}

// ── Render ──
function render(){
  renderBlocList();
  $('hB').textContent=Object.keys(states).length;
  $('hE').textContent=events.length;
  if(curTab==='timeline') renderFeed();
  if(curTab==='lifecycle') renderLifecycle();
  if(curTab==='analytics') renderAnalytics();
}

function renderBlocList(){
  const names=Object.keys(states);
  if(!names.length){$('bList').innerHTML='<div style="padding:10px;color:var(--tx2);font-size:11px">No active blocs</div>';return}
  $('bList').innerHTML=names.map(n=>{
    const cnt=events.filter(e=>e.bloc===n).length;
    const freq=frequencies[n]||0;
    const fStr=freq>10?'<span class="bloc-freq warn">'+freq.toFixed(1)+'/s</span>':freq>0?'<span class="bloc-freq">'+freq.toFixed(1)+'/s</span>':'';
    const sel=pickedBloc===n?' sel':'';
    return '<div class="bloc-entry'+sel+'" onclick="toggleBloc(\''+h(n)+'\')">'
      +'<span>'+h(n)+fStr+'</span><span class="cnt">'+cnt+'</span></div>';
  }).join('');
}

function renderFeed(){
  const q=$('searchBox').value.toLowerCase();
  let list=events;
  if(pickedBloc) list=list.filter(e=>e.bloc===pickedBloc);
  if(q) list=list.filter(e=>e.bloc.toLowerCase().includes(q)||e.type.includes(q));
  if(!list.length){$('feed').innerHTML='<div class="placeholder">No events to display</div>';return}

  $('feed').innerHTML=list.map(e=>{
    const t=new Date(e.timestamp).toLocaleTimeString('en-GB',{hour12:false});
    const act=pickedEv===e?' act':'';
    const idx=events.indexOf(e);
    const ms=e.durationMs||0;
    const msClass=ms>100?' slow':'';
    let sum='';
    if(e.event){sum=typeof e.event==='object'?(e.event._type||''):String(e.event).substring(0,40)}
    return '<div class="ev'+act+'" onclick="pickEvent('+idx+')">'
      +'<span class="ev-t">'+t+'</span>'
      +'<span class="ev-tag '+e.type+'">'+e.type+'</span>'
      +'<span class="ev-bloc">'+h(e.bloc)+'</span>'
      +'<span class="ev-ms'+msClass+'">'+(ms>0?ms+'ms':'')+'</span>'
      +'<span class="ev-sum">'+h(sum)+'</span></div>';
  }).join('');
  $('feed').scrollTop=$('feed').scrollHeight;
}

// ── Lifecycle page ──
function renderLifecycle(){
  if(!lifecycles.length){$('lcContainer').innerHTML='<div class="placeholder">No lifecycle data yet</div>';return}
  const earliest=new Date(lifecycles[0].created).getTime();
  const now=Date.now();
  const span=Math.max(now-earliest,1000);

  let html='<div class="lc-legend"><span><span class="lc-legend-dot" style="background:var(--green-s);border:1px solid var(--green)"></span>Active</span><span><span class="lc-legend-dot" style="background:var(--red-s);border:1px solid var(--red)"></span>Closed</span></div>';

  // Group by bloc name
  const byName={};
  lifecycles.forEach(lc=>{if(!byName[lc.bloc]) byName[lc.bloc]=[];byName[lc.bloc].push(lc)});

  for(const name of Object.keys(byName)){
    const entries=byName[name];
    let bars='';
    for(const lc of entries){
      const s=new Date(lc.created).getTime();
      const e=lc.closed?new Date(lc.closed).getTime():now;
      const left=((s-earliest)/span*100).toFixed(2);
      const width=((e-s)/span*100).toFixed(2);
      const cls=lc.closed?'dead':'alive';
      const dur=lc.closed?((e-s)/1000).toFixed(1)+'s':'active';
      bars+='<div class="lc-bar '+cls+'" style="left:'+left+'%;width:'+width+'%" title="'+dur+'"></div>';
    }
    const total=entries.length;
    const openCount=entries.filter(x=>!x.closed).length;
    html+='<div class="lc-row"><span class="lc-name">'+h(name)+'</span><div class="lc-bar-wrap">'+bars+'</div><span class="lc-time">'+total+'x'+(openCount?' ('+openCount+' open)':'')+'</span></div>';
  }
  $('lcContainer').innerHTML=html;
}

// ── Analytics page ──
function renderAnalytics(){
  // Frequency table
  const fBody=$('freqTable').querySelector('tbody');
  const fNames=Object.keys(frequencies).sort((a,b)=>(frequencies[b]||0)-(frequencies[a]||0));
  const maxFreq=Math.max(...fNames.map(n=>frequencies[n]||0),1);
  fBody.innerHTML=fNames.map(n=>{
    const cnt=events.filter(e=>e.bloc===n).length;
    const rate=frequencies[n]||0;
    const hi=rate>10?' hi':'';
    const barW=Math.round(rate/maxFreq*80);
    return '<tr><td class="nm">'+h(n)+'</td><td>'+cnt+'</td><td class="'+hi+'">'+rate.toFixed(2)+'</td><td><span class="bar-tiny" style="width:'+barW+'px"></span></td></tr>';
  }).join('')||'<tr><td colspan="4" style="color:var(--tx2)">No data</td></tr>';

  // Size table
  const sBody=$('sizeTable').querySelector('tbody');
  const sNames=Object.keys(stateSizes).sort((a,b)=>(stateSizes[b]||0)-(stateSizes[a]||0));
  const maxSize=Math.max(...sNames.map(n=>stateSizes[n]||0),1);
  sBody.innerHTML=sNames.map(n=>{
    const sz=stateSizes[n]||0;
    const hi=sz>5000?' hi':'';
    const barW=Math.round(sz/maxSize*80);
    const label=sz>1024?(sz/1024).toFixed(1)+' KB':sz+' B';
    return '<tr><td class="nm">'+h(n)+'</td><td class="'+hi+'">'+label+'</td><td><span class="bar-tiny" style="width:'+barW+'px"></span></td></tr>';
  }).join('')||'<tr><td colspan="3" style="color:var(--tx2)">No data</td></tr>';
}

// ── Interactions ──
function toggleBloc(name){
  pickedBloc=pickedBloc===name?null:name;
  render();
  if(pickedBloc&&states[pickedBloc]!==undefined){
    showDetail('State: '+pickedBloc,[{label:null,data:states[pickedBloc]}],{showCopy:true,copyData:states[pickedBloc]});
  } else {$('pDetail').classList.remove('open')}
}

function pickEvent(idx){
  pickedEv=events[idx];
  render();
  const e=pickedEv;
  const parts=[];
  // Diff section
  if(e.prevState!==undefined&&e.state!==undefined){
    parts.push({label:'State Diff',diff:true,prev:e.prevState,next:e.state});
  }
  if(e.state!==undefined) parts.push({label:'Current State',data:e.state});
  if(e.event!==undefined) parts.push({label:'Event',data:e.event});
  if(e.error) parts.push({label:'Error',data:e.error});
  if(e.stackTrace) parts.push({label:'Stack Trace',data:e.stackTrace});

  const meta={durationMs:e.durationMs,stateSize:e.stateSize,frequency:e.frequency};
  showDetail(e.type.toUpperCase()+' \u2014 '+e.bloc,parts,{meta,showCopy:true,copyData:e.state});
}

function showDetail(title,sections,opts={}){
  const p=$('pDetail');p.classList.add('open');
  let out='<div class="d-head"><span>'+h(title)+'</span>';
  if(opts.showCopy) out+='<button class="btn btn-accent" onclick="copyJson()">Copy JSON</button>';
  out+='</div>';

  // Meta bar
  if(opts.meta){
    const m=opts.meta;
    out+='<div class="d-meta">';
    if(m.durationMs!==undefined) out+='<span>Duration: <span class="val'+(m.durationMs>100?' warn':'')+'">'+m.durationMs+'ms</span></span>';
    if(m.stateSize!==undefined){const l=m.stateSize>1024?(m.stateSize/1024).toFixed(1)+' KB':m.stateSize+' B';out+='<span>Size: <span class="val'+(m.stateSize>5000?' warn':'')+'">'+l+'</span></span>'}
    if(m.frequency!==undefined) out+='<span>Rate: <span class="val'+(m.frequency>10?' warn':'')+'">'+m.frequency.toFixed(1)+'/s</span></span>';
    out+='</div>';
  }

  for(const s of sections){
    if(s.label) out+='<div class="d-label">'+h(s.label)+'</div>';
    if(s.diff) out+=renderDiff(s.prev,s.next);
    else out+='<div class="tree">'+renderNode(s.data,0)+'</div>';
  }
  p.innerHTML=out;
  // Store copy data
  p.dataset.copyJson=JSON.stringify(opts.copyData||null,null,2);
  bindFolds();
}

function copyJson(){
  const json=$('pDetail').dataset.copyJson||'null';
  navigator.clipboard.writeText(json).then(()=>{
    const t=$('toast');t.classList.add('show');setTimeout(()=>t.classList.remove('show'),1500);
  });
}

// ── State Diff ──
function renderDiff(prev,next){
  if(prev===null||prev===undefined) return '<div class="diff-row diff-add">+ (initial state)</div>';
  if(typeof prev!=='object'||typeof next!=='object'){
    if(JSON.stringify(prev)===JSON.stringify(next)) return '<div class="diff-row diff-same">No changes</div>';
    return '<div class="diff-row diff-rem">- '+h(JSON.stringify(prev))+'</div><div class="diff-row diff-add">+ '+h(JSON.stringify(next))+'</div>';
  }
  const allKeys=new Set([...Object.keys(prev||{}),...Object.keys(next||{})]);
  let out='';let changes=0;
  for(const k of allKeys){
    if(k==='_type') continue;
    const pv=prev?prev[k]:undefined;
    const nv=next?next[k]:undefined;
    const pj=JSON.stringify(pv);
    const nj=JSON.stringify(nv);
    if(pv===undefined){
      out+='<div class="diff-row diff-add">+ '+h(k)+': '+h(nj)+'</div>';changes++;
    } else if(nv===undefined){
      out+='<div class="diff-row diff-rem">- '+h(k)+': '+h(pj)+'</div>';changes++;
    } else if(pj!==nj){
      out+='<div class="diff-row diff-rem">- '+h(k)+': '+h(pj)+'</div>';
      out+='<div class="diff-row diff-add">+ '+h(k)+': '+h(nj)+'</div>';changes++;
    } else {
      out+='<div class="diff-row diff-same">&nbsp; '+h(k)+': '+h(pj)+'</div>';
    }
  }
  if(!changes) out='<div class="diff-row diff-same">No changes detected</div>';
  return out;
}

// ── Tree ──
function renderNode(v,d){
  if(v===null||v===undefined) return '<span class="t-null">null</span>';
  if(typeof v==='boolean') return '<span class="t-bool">'+v+'</span>';
  if(typeof v==='number') return '<span class="t-num">'+v+'</span>';
  if(typeof v==='string'){
    if(/^[A-Z]\w*\.\w+$/.test(v)) return '<span class="t-enum">'+h(v)+'</span>';
    if(/^https?:\/\//.test(v)) return '<a href="'+h(v)+'" target="_blank" style="color:var(--cyan);text-decoration:none;word-break:break-all">'+h(v)+'</a>';
    return '<span class="t-str">'+h(v)+'</span>';
  }
  if(Array.isArray(v)){
    if(!v.length) return '<span class="t-null">[]</span>';
    const rows=v.map((x,i)=>'<div class="t-row" style="padding-left:'+((d+1)*12)+'px"><span style="color:var(--tx2);font-size:10px">['+i+']</span> '+renderNode(x,d+1)+'</div>').join('');
    return '<span class="t-fold">List ('+v.length+')</span><div class="t-kids t-grp">'+rows+'</div>';
  }
  if(typeof v==='object'){
    const keys=Object.keys(v);if(!keys.length) return '<span class="t-null">{}</span>';
    const dt=v['_type'];const fk=keys.filter(k=>k!=='_type');
    if(dt&&!fk.length) return '<span class="t-type">'+h(dt)+'</span>';
    const rows=fk.map(k=>'<div class="t-row" style="padding-left:'+((d+1)*12)+'px"><span class="t-key">'+h(k)+'</span>: '+renderNode(v[k],d+1)+'</div>').join('');
    if(dt) return '<span class="t-fold"><span class="t-type">'+h(dt)+'</span></span><div class="t-kids t-grp">'+rows+'</div>';
    return '<span class="t-fold">{'+keys.length+' fields}</span><div class="t-kids t-grp">'+rows+'</div>';
  }
  return '<span>'+h(String(v))+'</span>';
}

function bindFolds(){document.querySelectorAll('.t-fold').forEach(el=>{if(el.dataset.b)return;el.dataset.b='1';el.onclick=ev=>{ev.stopPropagation();el.classList.toggle('shut');el.nextElementSibling.classList.toggle('collapsed')}})}
function h(s){if(typeof s!=='string')s=String(s);return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;')}

// ── Init ──
$('btnClear').onclick=()=>{events=[];pickedEv=null;render();$('pDetail').classList.remove('open')};
$('searchBox').oninput=()=>renderFeed();
connect();
</script>
</body>
</html>
''';
