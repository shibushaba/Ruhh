#!/usr/bin/env python3
"""Emit static RUHH Phase 1 frames. Not part of the Flutter app."""

from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "screens"

NAV = """
<nav class="tabs" aria-label="Primary">
  <div class="tab on ico">&#xe2c2;</div>
  <div class="tab ico">&#xe68a;</div>
  <div class="tab ico">&#xe184;</div>
  <div class="tab ico">&#xe58e;</div>
  <div class="tab ico">&#xe8c2;</div>
  <div class="tab ico">&#xe0ee;</div>
</nav>
"""

SCREENS = {}

SCREENS["home"] = f"""
<div class="phone">
  <header class="top">
    <div class="iconbtn">&#xe0ce;</div>
    <h1>Home</h1>
    <div class="avatar">You</div>
  </header>
  <article class="card pad journey">
    <div class="screen-label">My Journey</div>
    <div class="row" style="margin-top:6px">
      <div>
        <div class="level">8<span>Level</span></div>
        <div class="title">Keeping promises</div>
      </div>
      <div class="xpmeta"><b>1,094</b>lifetime XP</div>
    </div>
    <div class="bar" aria-hidden="true"><i style="width:31%"></i></div>
    <div class="barlabel"><span>Level 8</span><span>161 to level 9</span></div>
    <div class="season">
      <div><b>Ninety days on the business</b><br><em>Day 18 · optional focus</em></div>
      <div class="tag">Kept</div>
    </div>
  </article>
  <p class="quiet">Three quiet days. Nothing was taken back.</p>
  <h2 class="block">Today</h2>
  <p class="sub">From your plans. Nothing invented.</p>
  <div class="list">
    <div class="card rowitem">
      <div class="accent" style="background:var(--habit)"></div>
      <div><div class="name">Write for 25 minutes</div><div class="meta">Habit · due today · streak 11</div></div>
      <div class="check"></div>
    </div>
    <div class="card rowitem">
      <div class="accent" style="background:var(--sky)"></div>
      <div><div class="name">Ship the landing page</div><div class="meta">Quest · from milestone “Build an MVP”</div></div>
      <div class="tag">Open</div>
    </div>
    <div class="card rowitem">
      <div class="accent" style="background:var(--prayer)"></div>
      <div><div class="name">Prayers · 2 of 5 marked</div><div class="meta">Prayer tracker · not part of XP</div></div>
      <div class="tag">Log</div>
    </div>
  </div>
  <h2 class="block">Active goals</h2>
  <div class="list">
    <div class="card rowitem">
      <div class="accent" style="background:var(--sky)"></div>
      <div><div class="name">Build a software business</div><div class="meta">Career &amp; Business · 1 of 6 milestones</div></div>
      <div class="frac">1/6</div>
    </div>
    <div class="card rowitem">
      <div class="accent" style="background:var(--book)"></div>
      <div><div class="name">Read 12 books this year</div><div class="meta">Knowledge &amp; Learning · 3 of 12 finished</div></div>
      <div class="frac">3/12</div>
    </div>
  </div>
  {NAV}
</div>
"""

SCREENS["journey"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">Home</div></div>
  <div class="screen-label">My Journey</div>
  <div class="title" style="font-size:28px;line-height:34px;font-weight:800;letter-spacing:0.4px">The record so far</div>
  <article class="card pad" style="margin-top:12px">
    <div class="row">
      <div>
        <div class="level">8<span>Keeping promises</span></div>
      </div>
      <div class="xpmeta"><b>1,094</b>lifetime XP</div>
    </div>
    <div class="bar" style="margin-top:12px"><i style="width:31%"></i></div>
    <div class="barlabel"><span>Since 3 Mar 2026</span><span>Never reset</span></div>
  </article>
  <p class="quiet">Seasons end. This does not. A missed day is a gap in the line, not a debt.</p>
  <h2 class="block">Path</h2>
  <div class="rail" style="margin-top:10px">
    <div class="event"><div class="stem"><i class="now"></i><b></b></div><div class="body"><div class="when">TODAY</div><div class="what">Level 8, since 12 Nov</div><div class="why">161 XP to level 9 · the crossing was a milestone, once</div></div></div>
    <div class="event"><div class="stem"><i class="done"></i><b></b></div><div class="body"><div class="when">12 NOV · +40 XP</div><div class="what">Milestone · Validate the idea</div><div class="why">Goal · Build a software business</div></div></div>
    <div class="event"><div class="stem"><i class="done"></i><b></b></div><div class="body"><div class="when">2 NOV</div><div class="what">Achievement · First week kept</div><div class="why">Once. The streak can break later. This stays.</div></div></div>
    <div class="gapnote">28–30 Oct · away. Streak paused. Lifetime XP unchanged.</div>
    <div class="event"><div class="stem"><i class="done"></i><b></b></div><div class="body"><div class="when">14 OCT · +8 XP</div><div class="what">Habit · Write for 25 minutes</div><div class="why">One award for that day. Not per minute.</div></div></div>
  </div>
  <div class="btnrow">
    <div class="btn ghost">Achievements</div>
    <div class="btn ghost">Season</div>
  </div>
  {NAV}
</div>
"""

SCREENS["goal"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">Career &amp; Business</div></div>
  <div class="screen-label">Goal · long</div>
  <div class="milestone-title">Build a software business</div>
  <p class="sub" style="margin-top:4px">A practice that pays, without you in every hour.</p>
  <article class="card pad" style="margin-top:12px">
    <div class="row"><div class="screen-label">Milestones</div><div class="frac">1/6</div></div>
    <div class="bar" style="margin-top:10px"><i style="width:17%"></i></div>
    <p class="sub" style="margin-top:8px">Done over not-dropped. Habits do not move this bar.</p>
  </article>
  <div class="rail">
    <div class="event"><div class="stem"><i class="done"></i><b></b></div><div class="body"><div class="when">DONE · 12 NOV</div><div class="what">Validate the idea</div><div class="why">+40 XP · recorded once</div></div></div>
    <div class="event"><div class="stem"><i class="now"></i><b></b></div><div class="body"><div class="when">IN PROGRESS</div><div class="what">Build an MVP</div><div class="why">Project linked · Build the MVP</div></div></div>
    <div class="event"><div class="stem"><i></i><b></b></div><div class="body"><div class="when">WAITING</div><div class="what">First customer</div><div class="why">After “Build an MVP”</div></div></div>
    <div class="event"><div class="stem"><i></i><b></b></div><div class="body"><div class="when">LATER</div><div class="what">Five paying customers</div></div></div>
    <div class="event"><div class="stem"><i></i><b></b></div><div class="body"><div class="when">LATER</div><div class="what">Repeatable sales</div></div></div>
    <div class="event"><div class="stem"><i></i></div><div class="body"><div class="when">LINKED MONEY GOAL</div><div class="what">A steady month of revenue</div><div class="why">Points at budget objective “Monthly revenue”. Does not merge with it.</div></div></div>
  </div>
  <article class="card support">
    <div><div class="name">Weekly outreach</div><div class="meta">Supporting habit · streak 4 · cannot complete this goal</div></div>
    <div class="tag">Habit</div>
  </article>
  {NAV}
</div>
"""

SCREENS["project"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">Build an MVP</div></div>
  <div class="screen-label">Project</div>
  <div class="milestone-title">Build the MVP</div>
  <p class="sub" style="margin-top:4px">How the milestone gets done. The milestone stays the “what”.</p>
  <article class="card" style="margin-top:14px">
    <div class="task done"><div class="check on"></div><div><div class="name">Write the offer</div><div class="meta">Done · 10 Nov</div></div></div>
    <div class="task"><div class="check"></div><div><div class="name">Landing page</div><div class="meta">Due today · also today’s quest</div></div></div>
    <div class="subtasks"><div>Headline</div><div>A way to reply</div></div>
    <div class="task"><div class="check"></div><div><div class="name">Ask three people to try it</div><div class="meta">No date</div></div></div>
  </article>
  <div class="callout">Finishing every task asks whether the project is done. It does not complete the milestone by itself, and it does not pay XP twice.</div>
  <article class="card pad" style="margin-top:12px">
    <div class="screen-label">If you mark the project done</div>
    <p class="sub" style="margin-top:6px">One project award, unless the milestone rule already names this project. Then only the milestone pays.</p>
  </article>
  {NAV}
</div>
"""

SCREENS["planner"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">Home</div></div>
  <div class="screen-label">Today’s plan</div>
  <div class="milestone-title">Thursday 16 Nov</div>
  <p class="sub" style="margin-top:4px">The same records as Habit, Prayer, and your projects.</p>
  <h2 class="block">Due</h2>
  <div class="list">
    <div class="card rowitem">
      <div class="accent" style="background:var(--habit)"></div>
      <div><div class="name">Write for 25 minutes</div><div class="meta">Habit · checking here writes the habit</div></div>
      <div class="check"></div>
    </div>
    <div class="card rowitem">
      <div class="accent" style="background:var(--sky)"></div>
      <div><div class="name">Ship the landing page</div><div class="meta">Quest generated from the open task</div></div>
      <div class="check"></div>
    </div>
  </div>
  <h2 class="block">This week, from a goal</h2>
  <div class="list">
    <div class="card rowitem">
      <div class="accent" style="background:var(--sky)"></div>
      <div><div class="name">Build an MVP</div><div class="meta">Milestone in progress · not a new chore</div></div>
      <div class="tag">Open</div>
    </div>
  </div>
  <h2 class="block">Prayer</h2>
  <div class="list">
    <div class="card rowitem">
      <div class="accent" style="background:var(--prayer)"></div>
      <div><div class="name">2 of 5 marked</div><div class="meta">Opens the prayer tracker. Awards no XP.</div></div>
      <div class="tag">Separate</div>
    </div>
  </div>
  <p class="quiet">Nothing else is due. An empty afternoon is allowed.</p>
  <p class="quiet">Dismissed earlier: “Read chapter 4” · not today. The book stays on the shelf.</p>
  {NAV}
</div>
"""

SCREENS["levelup"] = f"""
<div class="phone">
  <header class="top">
    <div class="iconbtn">&#xe0ce;</div>
    <h1>Home</h1>
    <div class="avatar">You</div>
  </header>
  <article class="card pad journey" style="opacity:0.4">
    <div class="screen-label">My Journey</div>
    <div class="level" style="margin-top:6px">7<span>Level</span></div>
    <div class="title">Keeping promises</div>
    <div class="bar" style="margin-top:12px"><i style="width:86%"></i></div>
    <div class="barlabel"><span>990 lifetime</span><span>30 to level 8</span></div>
  </article>
  <div class="list" style="opacity:0.28;margin-top:12px">
    <div class="card rowitem"><div class="accent" style="background:var(--habit)"></div><div><div class="name">Write for 25 minutes</div><div class="meta">Habit · due today</div></div><div class="check"></div></div>
    <div class="card rowitem"><div class="accent" style="background:var(--sky)"></div><div><div class="name">Ship the landing page</div><div class="meta">Quest · from the MVP</div></div><div class="tag">Open</div></div>
  </div>
  <div class="scrim">
    <article class="card moment">
      <i class="burst" style="top:16px;right:28px;background:var(--mint)"></i>
      <i class="burst" style="top:36px;right:58px;background:var(--amber)"></i>
      <i class="burst" style="top:22px;right:78px;background:var(--sky);width:4px;height:4px"></i>
      <i class="burst" style="top:48px;right:22px;background:var(--lavender);width:4px;height:4px"></i>
      <div class="screen-label">Level</div>
      <h3>8</h3>
      <div class="title">Keeping promises</div>
      <div class="plusxp">+40 XP · now 1,030</div>
      <p class="sub" style="margin-top:4px">Milestone completed · Validate the idea. Crossed 1,020 into level 8.</p>
      <div class="chips"><div class="chip">Recorded once</div><div class="chip">Will not be added again</div></div>
      <div class="btnrow"><div class="btn">Continue</div></div>
    </article>
  </div>
</div>
"""

SCREENS["achievements"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">My Journey</div></div>
  <div class="screen-label">Achievements</div>
  <div class="milestone-title">What has already happened</div>
  <p class="sub" style="margin-top:4px">Unlocks stay when a streak resets.</p>
  <h2 class="block">Consistency</h2>
  <article class="card ach" style="margin-top:8px">
    <div class="mark" style="color:var(--mint)">7</div>
    <div><div class="name">First week kept</div><div class="meta">Unlocked 2 Nov · any one habit, seven scheduled days</div></div>
    <div class="rarity">Common</div>
  </article>
  <h2 class="block">Goal completion</h2>
  <article class="card ach" style="margin-top:8px">
    <div class="mark" style="color:var(--sky)">1</div>
    <div><div class="name">Idea on paper</div><div class="meta">Unlocked 12 Nov · first milestone on a long goal</div></div>
    <div class="rarity">Uncommon</div>
  </article>
  <h2 class="block">Long-term dedication</h2>
  <article class="card ach locked" style="margin-top:8px">
    <div class="mark">—</div>
    <div>
      <div class="name">A year of showing up</div>
      <div class="meta">18 days with a real completion. No penalty for the rest.</div>
      <div class="mini"><i style="width:5%"></i></div>
    </div>
    <div class="tag">Rare</div>
  </article>
  <div class="callout">Spirituality has no automatic achievement. Prayer is never scored. You can write your own, and RUHH will not invent one.</div>
  {NAV}
</div>
"""

SCREENS["season"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">My Journey</div></div>
  <div class="screen-label">Season · optional</div>
  <div class="milestone-title">Ninety days on the business</div>
  <p class="sub" style="margin-top:4px">A focus. Not a life reset. Day 18 of 90.</p>
  <article class="card pad" style="margin-top:14px">
    <div class="bar"><i style="width:20%"></i></div>
    <div class="barlabel"><span>Active</span><span>72 days left</span></div>
    <p class="sub" style="margin-top:10px">You can pause, extend, or leave. Level 8 and 1,094 lifetime XP stay either way.</p>
  </article>
  <h2 class="block">Inside this season</h2>
  <div class="list">
    <div class="card rowitem"><div class="accent" style="background:var(--sky)"></div><div><div class="name">Build a software business</div><div class="meta">Goal</div></div><div class="tag">In</div></div>
    <div class="card rowitem"><div class="accent" style="background:var(--habit)"></div><div><div class="name">Weekly outreach</div><div class="meta">Habit</div></div><div class="tag">In</div></div>
    <div class="card rowitem"><div class="accent" style="background:var(--sky)"></div><div><div class="name">Build the MVP</div><div class="meta">Project</div></div><div class="tag">In</div></div>
  </div>
  <p class="quiet">Prayer, movies, and books are not pulled in unless you add them. Adding a book still awards no XP.</p>
  <div class="btnrow">
    <div class="btn ghost">Pause</div>
    <div class="btn ghost">Extend</div>
    <div class="btn">Leave</div>
  </div>
  {NAV}
</div>
"""

SCREENS["domains"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">Home</div></div>
  <div class="screen-label">Life domains</div>
  <div class="milestone-title">Where goals live</div>
  <p class="sub" style="margin-top:4px">Counts of open goals. Not a percentage of a life.</p>
  <article class="card" style="margin-top:12px">
    <div class="drow"><div class="handle">↕</div><div class="accent" style="background:#4ade80;height:28px"></div><div><div class="name">Health &amp; Fitness</div><div class="meta">1 open goal</div></div><div class="tag">Edit</div></div>
    <div class="drow"><div class="handle">↕</div><div class="accent" style="background:#a78bfa;height:28px"></div><div><div class="name">Spirituality</div><div class="meta">0 open · prayer stays outside XP</div></div><div class="tag">Edit</div></div>
    <div class="drow"><div class="handle">↕</div><div class="accent" style="background:#fbbf24;height:28px"></div><div><div class="name">Knowledge &amp; Learning</div><div class="meta">1 open goal</div></div><div class="tag">Edit</div></div>
    <div class="drow"><div class="handle">↕</div><div class="accent" style="background:#94a3b8;height:28px"></div><div><div class="name">Discipline</div><div class="meta">0 open</div></div><div class="tag">Edit</div></div>
    <div class="drow"><div class="handle">↕</div><div class="accent" style="background:#38bdf8;height:28px"></div><div><div class="name">Career &amp; Business</div><div class="meta">1 open goal</div></div><div class="tag">Edit</div></div>
    <div class="drow"><div class="handle">↕</div><div class="accent" style="background:#fb923c;height:28px"></div><div><div class="name">Financial Growth</div><div class="meta">Linked budget objective · INR stays in Budget</div></div><div class="tag">Edit</div></div>
    <div class="drow"><div class="handle">↕</div><div class="accent" style="background:#fb7185;height:28px"></div><div><div class="name">Relationships</div><div class="meta">0 open</div></div><div class="tag">Edit</div></div>
    <div class="drow"><div class="handle">↕</div><div class="accent" style="background:var(--ink);height:28px"></div><div><div class="name">Personal Development</div><div class="meta">0 open</div></div><div class="tag">Edit</div></div>
  </article>
  <p class="arch">Archived · “Side projects” · history kept, hidden from Home.</p>
  <div class="btnrow"><div class="btn">Add a domain</div></div>
  {NAV}
</div>
"""


def page(theme: str, body: str) -> str:
    return f"""<!DOCTYPE html>
<html lang="en" data-theme="{theme}">
<head>
  <meta charset="utf-8">
  <title>RUHH {theme}</title>
  <link rel="stylesheet" href="../ruhh.css">
</head>
<body>
{body}
</body>
</html>
"""


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, body in SCREENS.items():
        for theme in ("dark", "light"):
            (OUT / f"{name}-{theme}.html").write_text(page(theme, body), encoding="utf-8")
    print(f"wrote {len(SCREENS) * 2} screens")


if __name__ == "__main__":
    main()
