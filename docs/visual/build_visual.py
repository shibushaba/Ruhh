#!/usr/bin/env python3
"""Static frames for the RUHH visual overhaul. Not app code."""

from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "screens"

DOCK = """
<nav class="dock" aria-label="Primary">
  <div class="tab on ico">&#xe2c2;</div>
  <div class="tab ico">&#xe68a;</div>
  <div class="tab ico">&#xe184;</div>
  <div class="tab ico">&#xe58e;</div>
  <div class="tab ico">&#xe8c2;</div>
  <div class="tab ico">&#xe0ee;</div>
</nav>
"""


def medal(n: str = "8") -> str:
    return f"""
<svg width="78" height="78" viewBox="0 0 78 78" aria-hidden="true">
  <defs>
    <linearGradient id="ring" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="var(--mint)"/>
      <stop offset="1" stop-color="var(--sky)"/>
    </linearGradient>
  </defs>
  <circle cx="39" cy="39" r="36" fill="none" stroke="url(#ring)" stroke-width="1.4"/>
  <circle cx="39" cy="39" r="30" fill="var(--surface)"/>
  <text x="39" y="47" text-anchor="middle" font-family="Outfit, sans-serif" font-size="28" fill="var(--ink)">{n}</text>
</svg>
"""


def ring(pct: float = 0.18) -> str:
    c = 2 * 3.1416 * 18
    dash = c * pct
    cap = "butt" if pct <= 0 else "round"
    return f"""
<svg width="52" height="52" viewBox="0 0 52 52" aria-hidden="true">
  <circle cx="26" cy="26" r="18" fill="none" stroke="var(--line)" stroke-width="3"/>
  <circle cx="26" cy="26" r="18" fill="none" stroke="var(--mint)" stroke-width="3"
    stroke-linecap="{cap}" stroke-dasharray="{dash:.1f} {c:.1f}" transform="rotate(-90 26 26)"/>
</svg>
"""


def path_plate() -> str:
    return """
<div class="path-plate" aria-hidden="true">
  <svg viewBox="0 0 346 158">
    <defs>
      <radialGradient id="pg" cx="42%" cy="45%" r="40%">
        <stop offset="0" stop-color="var(--mint)" stop-opacity="0.35"/>
        <stop offset="1" stop-color="var(--mint)" stop-opacity="0"/>
      </radialGradient>
      <linearGradient id="stroke" x1="0" y1="0" x2="1" y2="0">
        <stop offset="0" stop-color="var(--mint)"/>
        <stop offset="0.45" stop-color="var(--sky)"/>
        <stop offset="1" stop-color="var(--faint)" stop-opacity="0.45"/>
      </linearGradient>
    </defs>
    <rect width="346" height="158" fill="var(--surface)"/>
    <ellipse cx="150" cy="78" rx="90" ry="48" fill="url(#pg)"/>
    <path d="M28 118 C 78 118, 96 62, 150 66 S 250 108, 322 40" fill="none" stroke="rgba(0,0,0,0.35)" stroke-width="5" transform="translate(0 5)" stroke-linecap="round"/>
    <path d="M28 118 C 78 118, 96 62, 150 66 S 250 108, 322 40" fill="none" stroke="url(#stroke)" stroke-width="2.4" stroke-linecap="round"/>
    <circle cx="36" cy="114" r="5" fill="var(--mint)"/>
    <circle cx="150" cy="66" r="8" fill="var(--surface)" stroke="var(--mint)" stroke-width="2.5"/>
    <circle cx="150" cy="66" r="3" fill="var(--mint)"/>
    <circle cx="214" cy="86" r="4" fill="none" stroke="var(--faint)" stroke-width="1.4"/>
    <circle cx="262" cy="72" r="4" fill="none" stroke="var(--faint)" stroke-width="1.4"/>
    <circle cx="300" cy="52" r="4" fill="none" stroke="var(--faint)" stroke-width="1.4"/>
    <circle cx="322" cy="40" r="4" fill="none" stroke="var(--faint)" stroke-width="1.4"/>
    <text x="150" y="96" text-anchor="middle" fill="var(--muted)" font-family="DM Sans, sans-serif" font-size="11">You are here</text>
  </svg>
</div>
"""


def room() -> str:
    return """
<div class="room-wrap">
  <svg viewBox="0 0 346 250" aria-hidden="true">
    <defs>
      <linearGradient id="win" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#38bdf8" stop-opacity="0.65"/>
        <stop offset="1" stop-color="#38bdf8" stop-opacity="0.05"/>
      </linearGradient>
      <radialGradient id="lamp" cx="70%" cy="48%" r="42%">
        <stop offset="0" stop-color="#fbbf24" stop-opacity="0.55"/>
        <stop offset="0.5" stop-color="#fbbf24" stop-opacity="0.12"/>
        <stop offset="1" stop-color="#fbbf24" stop-opacity="0"/>
      </radialGradient>
      <linearGradient id="floor" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#2a2a32"/>
        <stop offset="1" stop-color="#141418"/>
      </linearGradient>
    </defs>
    <rect width="346" height="250" fill="#101014"/>
    <path d="M18 36 H328 V156 H18 Z" fill="#18181e"/>
    <rect x="36" y="52" width="78" height="86" rx="3" fill="url(#win)"/>
    <path d="M36 95 H114 M75 52 V138" stroke="rgba(255,255,255,0.28)" fill="none"/>
    <path d="M16 156 L173 196 L330 156 L173 118 Z" fill="url(#floor)"/>
    <ellipse cx="236" cy="162" rx="78" ry="30" fill="url(#lamp)"/>
    <path d="M150 146 H268 L286 164 H168 Z" fill="#32323a"/>
    <path d="M168 164 H286 V172 H168 Z" fill="#1a1a20"/>
    <path d="M236 146 V98" stroke="#f4f4f5" stroke-width="2"/>
    <path d="M218 96 H254 L248 108 H224 Z" fill="#f4f4f5"/>
    <g transform="translate(48 168)">
      <rect width="54" height="9" rx="1" y="22" fill="#fbbf24"/>
      <rect width="50" height="9" rx="1" x="3" y="13" fill="#38bdf8"/>
      <rect width="46" height="9" rx="1" x="5" y="4" fill="#fb7185"/>
    </g>
    <g transform="translate(292 150)" fill="#4ade80">
      <path d="M12 42 V22" stroke="#4ade80" stroke-width="1.6"/>
      <ellipse cx="12" cy="16" rx="9" ry="6"/>
      <ellipse cx="5" cy="20" rx="6" ry="4" fill="#34d399"/>
      <ellipse cx="19" cy="20" rx="6" ry="4" fill="#059669"/>
    </g>
    <path d="M40 188 C 110 176, 150 198, 200 176 S 280 150, 320 166" fill="none" stroke="#4ade80" stroke-width="1.6" stroke-linecap="round"/>
  </svg>
  <div class="pin" style="left:46px;bottom:28px">3 of 12</div>
  <div class="pin" style="right:28px;top:86px">Lit</div>
</div>
"""


def glyph(kind: str) -> str:
    paths = {
        "heart": '<path d="M11 18s-7-4.2-7-8.2A3.6 3.6 0 0 1 11 7a3.6 3.6 0 0 1 7 2.8C18 13.8 11 18 11 18z" fill="none" stroke="currentColor" stroke-width="1.4"/>',
        "moon": '<path d="M14 5a6 6 0 1 0 5 9 5 5 0 1 1-5-9z" fill="none" stroke="currentColor" stroke-width="1.4"/>',
        "book": '<path d="M5 6.5h6.2A2.8 2.8 0 0 1 14 9.3V17H7.2A2.2 2.2 0 0 0 5 19.2zM19 6.5h-6.2A2.8 2.8 0 0 0 10 9.3V17h6.8A2.2 2.2 0 0 1 19 19.2z" fill="none" stroke="currentColor" stroke-width="1.4"/>',
        "bolt": '<path d="M12 3 6 13h5l-1 8 7-11h-5z" fill="currentColor"/>',
        "lamp": '<path d="M8 18h8M12 18V10M8 10h8l-1.2-4h-5.6z" fill="none" stroke="currentColor" stroke-width="1.4"/>',
        "coin": '<circle cx="12" cy="12" r="6" fill="none" stroke="currentColor" stroke-width="1.4"/><path d="M12 9v6M10.2 10.5h2.6a1.3 1.3 0 0 1 0 2.6H10" fill="none" stroke="currentColor" stroke-width="1.2"/>',
        "people": '<circle cx="9" cy="9" r="2.2" fill="none" stroke="currentColor" stroke-width="1.3"/><circle cx="15" cy="9.5" r="1.8" fill="none" stroke="currentColor" stroke-width="1.3"/><path d="M5 17c.6-2.2 2.2-3.2 4-3.2s3.4 1 4 3.2M13 14.2c.8-.4 1.6-.5 2.4-.4 1.4.2 2.4 1.2 2.8 3.2" fill="none" stroke="currentColor" stroke-width="1.3"/>',
        "self": '<circle cx="12" cy="8" r="2.4" fill="none" stroke="currentColor" stroke-width="1.4"/><path d="M7 18c.5-3 2.4-4.4 5-4.4s4.5 1.4 5 4.4" fill="none" stroke="currentColor" stroke-width="1.4"/>',
    }
    return f'<svg class="glyph" viewBox="0 0 24 24" style="color:var(--c)">{paths[kind]}</svg>'


def tile(name, count, color, icon, wide=False) -> str:
    wide_cls = " wide" if wide else ""
    return f"""
<article class="tile{wide_cls}" style="--c:{color}">
  <div class="wash"></div>
  {glyph(icon)}
  <div class="name">{name}</div>
  <div class="count">{count}</div>
</article>
"""


def emblem_week() -> str:
    dots = []
    for i in range(7):
        a = -90 + i * (360 / 7)
        dots.append(
            f'<circle cx="40" cy="14" r="3.2" fill="var(--mint)" transform="rotate({a:.0f} 40 40)"/>'
        )
    return f'<svg width="80" height="80" viewBox="0 0 80 80">{"".join(dots)}<circle cx="40" cy="40" r="6" fill="none" stroke="var(--mint)" stroke-width="1.4"/></svg>'


def emblem_idea() -> str:
    return """
<svg width="80" height="80" viewBox="0 0 80 80">
  <circle cx="40" cy="40" r="22" fill="none" stroke="var(--sky)" stroke-width="1.2"/>
  <circle cx="40" cy="40" r="6" fill="var(--sky)"/>
</svg>
"""


def emblem_year() -> str:
    return """
<svg width="80" height="80" viewBox="0 0 80 80">
  <circle cx="40" cy="40" r="26" fill="none" stroke="var(--line)" stroke-width="3"/>
  <circle cx="40" cy="40" r="26" fill="none" stroke="var(--slate)" stroke-width="3" stroke-linecap="round"
    stroke-dasharray="18 146" transform="rotate(-90 40 40)"/>
</svg>
"""


SCREENS: dict[str, str] = {}

SCREENS["a-home"] = f"""
<div class="stage concept-a">
  <header class="top"><div class="ico">&#xe0ce;</div><div class="ask">Ask</div></header>
  <p class="eyebrow">Monday 16 November</p>
  <div class="arc-row" style="margin-top:8px">
    <div>
      <div class="giant">8</div>
      <p class="lede" style="margin-top:8px">Finding your rhythm</p>
      <p class="quiet">1,094 lifetime · 161 to level 9</p>
    </div>
    {ring(0.31).replace('52', '92').replace('26', '46').replace('18', '36')}
  </div>
  <div class="a-rule"></div>
  <p class="faint">Now</p>
  <h2 class="lede" style="margin-top:6px">Write for 25 minutes</h2>
  <p class="quiet" style="margin-top:8px">Then the landing page. Prayer is 2 of 5, and it is not scored.</p>
  <div class="a-rule"></div>
  <div class="a-goal"><b>Build a software business</b><span class="quiet">1 / 6</span></div>
  <div class="a-goal"><b>Read books</b><span class="quiet">3 / 12</span></div>
  <p class="quiet" style="margin-top:18px">Three quiet days. Nothing was taken back.</p>
  {DOCK}
</div>
"""

SCREENS["a-journey"] = f"""
<div class="stage concept-a">
  <div class="back"><span class="ico">&#xe138;</span> Home</div>
  <p class="eyebrow" style="margin-top:18px">My Journey</p>
  <div class="giant" style="font-size:78px">8</div>
  <p class="lede">Finding your rhythm</p>
  <p class="quiet">Since 3 March 2026. This number does not reset.</p>
  <div class="a-rule"></div>
  <p class="quiet">16 Nov · still level 8 · 161 to go</p>
  <p class="lede" style="font-size:18px;margin-top:14px">12 Nov · Validate the idea</p>
  <p class="quiet">+40 · once</p>
  <p class="lede" style="font-size:18px;margin-top:14px">2 Nov · First week kept</p>
  <p class="quiet">The streak can die. This stays.</p>
  <p class="quiet" style="margin-top:14px">28–30 Oct · away. A gap, not a debt.</p>
  <p class="lede" style="font-size:18px;margin-top:14px">14 Oct · Wrote for 25 minutes</p>
  <p class="quiet">+8 · one day, not per minute</p>
  {DOCK}
</div>
"""

SCREENS["b-home"] = f"""
<div class="stage concept-b">
  <header class="top"><div class="ico">&#xe0ce;</div><div class="ask">Ask</div></header>
  {room()}
  <p class="eyebrow">Level 8 · Finding your rhythm</p>
  <h2 class="lede" style="margin-top:4px">The lamp is on because the business is in progress.</h2>
  <p class="quiet" style="margin-top:8px">Now · write for 25 minutes. 1,094 lifetime. Nothing invented in the corners.</p>
  {DOCK}
</div>
"""

SCREENS["b-journey"] = f"""
<div class="stage concept-b">
  <div class="back"><span class="ico">&#xe138;</span> Home</div>
  <p class="eyebrow">The room, over time</p>
  <div class="station"><svg viewBox="0 0 72 72"><circle cx="36" cy="36" r="10" fill="var(--mint)"/><circle cx="36" cy="36" r="22" fill="none" stroke="var(--mint)" stroke-width="1"/></svg>
    <div><b>12 Nov</b><p class="quiet">A stone set in the floor. Validate the idea.</p></div></div>
  <div class="station"><svg viewBox="0 0 72 72"><path d="M30 50 V28 M22 26 H42 L38 34 H26 Z" fill="none" stroke="var(--amber)" stroke-width="1.6"/></svg>
    <div><b>Today</b><p class="quiet">The lamp stays lit on milestone two. You are here.</p></div></div>
  <div class="station"><svg viewBox="0 0 72 72"><rect x="22" y="40" width="28" height="6" fill="var(--amber)"/><rect x="24" y="32" width="24" height="6" fill="var(--sky)"/></svg>
    <div><b>This year</b><p class="quiet">Three books on the stack. Nine more before the year turns.</p></div></div>
  <p class="quiet" style="margin-top:16px">28–30 Oct the window was dark. The stones did not move.</p>
  {DOCK}
</div>
"""

SCREENS["home"] = f"""
<div class="stage">
  <header class="top"><div class="ico">&#xe0ce;</div><div class="ask">Ask</div></header>
  <p class="eyebrow">Monday 16 November</p>
  <div class="hero-row">
    {medal()}
    <div class="copy">
      <div class="faint">My Journey</div>
      <div class="title">Finding your rhythm</div>
      <p class="quiet">1,094 lifetime · 161 to level 9</p>
    </div>
  </div>
  {path_plate()}
  <section class="now">
    <div>
      <div class="faint">Now</div>
      <h2>Write for 25 minutes</h2>
    </div>
    {ring(0.0)}
  </section>
  <div class="subline"><span><i class="dot" style="background:var(--amber)"></i>Ship the landing page</span><span class="quiet">Quest</span></div>
  <div class="subline"><span><i class="dot" style="background:var(--lavender)"></i>Prayer · 2 of 5</span><span class="quiet">Not scored</span></div>
  <div class="goal-line" style="margin-top:20px">
    <div>
      <div class="faint">Active</div>
      <h3>Build a software business</h3>
      <svg class="mini-path" width="180" height="28" viewBox="0 0 180 28" aria-hidden="true">
        <path d="M4 20 C 30 20, 40 8, 70 10 S 120 22, 176 6" fill="none" stroke="var(--sky)" stroke-width="1.6" stroke-linecap="round"/>
        <circle cx="70" cy="10" r="3.5" fill="var(--sky)"/>
      </svg>
    </div>
    <div class="quiet">1 / 6</div>
  </div>
  <div class="goal-line">
    <div>
      <h3>Read books · 2026</h3>
      <p class="quiet">A year of its own. The shelf does not move this.</p>
    </div>
    <div class="measure">{ring(0.25)}<b>3/12</b></div>
  </div>
  <div class="shortcuts">
    <a><span class="ico">&#xe100;</span>Domains</a>
    <a><span class="ico">&#xe3d4;</span>New goal</a>
    <a><span class="ico">&#xe2c2;</span>My Space</a>
  </div>
  {DOCK}
</div>
"""

SCREENS["journey"] = f"""
<div class="stage">
  <div class="back"><span class="ico">&#xe138;</span> Home</div>
  <div class="hero-row">
    {medal()}
    <div class="copy">
      <div class="faint">Since 3 March 2026</div>
      <div class="title">The record so far</div>
      <p class="quiet">Level 8. It has never been reset.</p>
    </div>
  </div>
  {path_plate()}
  <div class="timeline">
    <div class="ev"><div class="rail"><i class="now"></i><b></b></div><div class="body"><div class="when">Today</div><div class="what">Still on the second stone</div><p class="quiet">161 XP to level 9</p></div></div>
    <div class="ev"><div class="rail"><i class="done"></i><b></b></div><div class="body"><div class="when">12 November · +40</div><div class="what">Validate the idea</div><p class="quiet">Recorded once</p></div></div>
    <div class="ev"><div class="rail"><i class="done"></i><b></b></div><div class="body"><div class="when">2 November</div><div class="what">First week kept</div><p class="quiet">The streak can break. This stays.</p></div></div>
    <div class="ev"><div class="rail"><i></i></div><div class="body"><div class="when">28–30 October</div><div class="what">Away</div><p class="quiet">A gap in the line. Nothing taken back.</p></div></div>
  </div>
  {DOCK}
</div>
"""

SCREENS["goal"] = f"""
<div class="stage">
  <div class="back"><span class="ico">&#xe138;</span> Career &amp; Business</div>
  <p class="eyebrow">Long goal</p>
  <h1 class="day" style="font-size:30px;letter-spacing:-0.8px;margin-top:4px">Build a software business</h1>
  <p class="quiet">A practice that pays, without you in every hour.</p>
  <div class="timeline" style="margin-top:18px">
    <div class="ev"><div class="rail"><i class="done"></i><b></b></div><div class="body"><div class="when">Done · 12 Nov</div><div class="what">Validate the idea</div></div></div>
    <div class="ev"><div class="rail"><i class="now"></i><b></b></div><div class="body"><div class="when">You are here</div><div class="what">Build an MVP</div><p class="quiet">The project is the how. This stone is the what.</p></div></div>
    <div class="ev"><div class="rail"><i></i><b></b></div><div class="body"><div class="what">First customer</div><p class="quiet">After the MVP</p></div></div>
    <div class="ev"><div class="rail"><i></i><b></b></div><div class="body"><div class="what">Five paying customers</div><p class="quiet">0 of 5</p></div></div>
    <div class="ev"><div class="rail"><i></i><b></b></div><div class="body"><div class="what">Repeatable sales</div></div></div>
    <div class="ev"><div class="rail"><i></i></div><div class="body"><div class="what">A steady month of revenue</div><p class="quiet">Points at a budget objective. It does not become one.</p></div></div>
  </div>
  {DOCK}
</div>
"""

SCREENS["domains"] = f"""
<div class="stage">
  <div class="back"><span class="ico">&#xe138;</span> Home</div>
  <h1 class="day" style="font-size:32px">Domains</h1>
  <p class="quiet">Where goals live. Counts, not a grade.</p>
  <div class="mosaic">
    {tile("Career & Business", "1 open goal", "var(--sky)", "lamp", wide=True)}
    {tile("Knowledge", "2026 · 3 of 12", "var(--amber)", "book")}
    {tile("Health", "1 open", "var(--mint)", "heart")}
    {tile("Spirituality", "Prayer is not scored", "var(--lavender)", "moon")}
    {tile("Discipline", "Quiet", "var(--slate)", "bolt")}
    {tile("Money", "Linked, in INR", "var(--peach)", "coin")}
    {tile("Relationships", "Nothing here yet", "var(--coral)", "people")}
    {tile("Personal", "Quiet", "var(--ink)", "self")}
  </div>
  {DOCK}
</div>
"""

SCREENS["planner"] = f"""
<div class="stage">
  <div class="back"><span class="ico">&#xe138;</span> Home</div>
  <p class="eyebrow">Monday</p>
  <h1 class="day">16</h1>
  <p class="quiet">November 2026</p>
  <section class="now">
    <div>
      <div class="faint">Now</div>
      <h2>Write for 25 minutes</h2>
      <p class="quiet">The same habit, wherever you check it.</p>
    </div>
    {ring(0)}
  </section>
  <ol class="spine">
    <li>Ship the landing page<em>Today’s quest, from the open task</em></li>
    <li class="later">Build an MVP<em>This week. The milestone, not a new chore.</em></li>
    <li class="pray">Prayer · 2 of 5<em>Separate. Awards nothing.</em></li>
  </ol>
  <p class="quiet">Nothing else is due. An empty afternoon is allowed.</p>
  {DOCK}
</div>
"""

SCREENS["ask"] = f"""
<div class="stage">
  <div class="back"><span class="ico">&#xe138;</span> Home</div>
  <p class="eyebrow">Ask</p>
  <p class="you">I want to learn React in 3 months.</p>
  <article class="letter">
    <div class="faint">Nothing is saved</div>
    <h2 class="lede" style="margin-top:8px">Learn React</h2>
    <p class="quiet">Knowledge &amp; Learning · medium</p>
    <ol class="spine" style="margin-top:12px">
      <li class="later">Say what “learn” means</li>
      <li class="later">Build a small thing</li>
      <li class="later">Use it on real work</li>
    </ol>
    <p class="quiet">Three short practices a week, if you want them. No XP until something is finished.</p>
    <div class="actions"><span class="linkish">Not now</span><span class="pill">Confirm</span></div>
  </article>
  {DOCK}
</div>
"""

SCREENS["achievements"] = f"""
<div class="stage">
  <div class="back"><span class="ico">&#xe138;</span> My Journey</div>
  <h1 class="day" style="font-size:32px">Already happened</h1>
  <p class="quiet">These stay when a streak dies.</p>
  <div class="emblems">
    <div>{emblem_week()}<p>First week<span>2 Nov</span></p></div>
    <div>{emblem_idea()}<p>Idea on paper<span>12 Nov</span></p></div>
    <div style="opacity:.55">{emblem_year()}<p>A year<span>18 days</span></p></div>
  </div>
  <p class="quiet" style="margin-top:28px">Spirituality has no automatic emblem. Prayer is never a score. You can write your own.</p>
  {DOCK}
</div>
"""

SCREENS["season"] = f"""
<div class="stage">
  <div class="back"><span class="ico">&#xe138;</span> My Journey</div>
  <p class="eyebrow">Optional chapter</p>
  <h1 class="day" style="font-size:30px;letter-spacing:-0.6px">Ninety days on the business</h1>
  <p class="quiet">Day 18 of 90. A focus, not a reset.</p>
  {path_plate()}
  <p class="quiet" style="margin-top:14px">Inside: the business goal, weekly outreach, the MVP. Prayer is not pulled in.</p>
  <p class="lede" style="font-size:18px;margin-top:16px">Leaving keeps level 8 and 1,094 XP.</p>
  <div class="actions"><span class="linkish">Pause</span><span class="pill">Leave</span></div>
  {DOCK}
</div>
"""

SCREENS["create"] = f"""
<div class="stage">
  <div class="back"><span class="ico">&#xe138;</span> Home</div>
  <p class="eyebrow">New goal</p>
  <h1 class="day" style="font-size:28px;letter-spacing:-0.6px">What are you aiming at?</h1>
  <div class="field">Build a software business</div>
  <div class="chips" style="margin-top:18px">
    <span class="chip on">Career</span><span class="chip">Knowledge</span><span class="chip">Health</span><span class="chip">Money</span>
  </div>
  <div class="chips">
    <span class="chip">Short</span><span class="chip">Medium</span><span class="chip on">Long</span><span class="chip">Recurring</span>
  </div>
  <p class="quiet" style="margin-top:16px">No target number. The path will be milestones. Creating this awards nothing.</p>
  <div class="actions"><span class="linkish">Cancel</span><span class="pill">Create</span></div>
  {DOCK}
</div>
"""

SCREENS["space"] = f"""
<div class="stage">
  <div class="back"><span class="ico">&#xe138;</span> Home</div>
  <p class="eyebrow">My Space</p>
  <h1 class="day" style="font-size:32px">Only what is real</h1>
  {room()}
  <p class="quiet" style="margin-top:12px">The lamp is the business, because that goal is in progress. The books are this year’s 3 of 12. Relationships has no goal, so that side of the room stays empty.</p>
  {DOCK}
</div>
"""


def page(theme: str, body: str) -> str:
    return f"""<!DOCTYPE html>
<html lang="en" data-theme="{theme}">
<head>
  <meta charset="utf-8">
  <title>RUHH {theme}</title>
  <link rel="stylesheet" href="../visual.css">
</head>
<body>
{body}
</body>
</html>
"""


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    both = {"home", "journey", "goal", "domains", "planner", "ask", "achievements", "season", "create", "space"}
    dark_only = {"a-home", "a-journey", "b-home", "b-journey"}
    n = 0
    for name, body in SCREENS.items():
        themes = ("dark",) if name in dark_only else ("dark", "light")
        if name not in both and name not in dark_only:
            themes = ("dark", "light")
        for theme in themes:
            (OUT / f"{name}-{theme}.html").write_text(page(theme, body), encoding="utf-8")
            n += 1
    print(f"wrote {n}")


if __name__ == "__main__":
    main()
