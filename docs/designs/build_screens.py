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
    <div class="ask">Ask</div>
    <div class="avatar">You</div>
  </header>
  <article class="card pad journey" style="padding:12px 14px">
    <div class="row">
      <div class="seal">8</div>
      <div style="flex:1;padding-left:12px">
        <div class="screen-label">My Journey</div>
        <div class="title">Finding your rhythm</div>
        <div class="dots" aria-hidden="true"><i class="on"></i><i class="on"></i><i class="on"></i><i class="on"></i><i class="on"></i><i class="on"></i><i class="on"></i><i class="now"></i></div>
      </div>
      <div class="xpmeta"><b>1,094</b>lifetime XP</div>
    </div>
    <div class="bar" aria-hidden="true"><i style="width:31%"></i></div>
    <div class="barlabel"><span>Level 8 · Mon 16 Nov 2026</span><span>161 to level 9</span></div>
    <div class="season">
      <div><b>Ninety days on the business</b> · day 18</div>
      <div class="tag">Kept</div>
    </div>
  </article>
  <p class="quiet">Three quiet days. Nothing was taken back.</p>
  <h2 class="block" style="margin-top:8px">Today</h2>
  <div class="list">
    <div class="card rowitem">
      <div class="accent" style="background:var(--habit)"></div>
      <div><div class="name"><span class="kind habit">Habit</span>Write for 25 minutes</div><div class="meta">Due today · streak 11</div></div>
      <div class="check"></div>
    </div>
    <div class="card rowitem">
      <div class="accent" style="background:var(--amber)"></div>
      <div><div class="name"><span class="kind quest">Quest</span>Ship the landing page</div><div class="meta">Today only · from the open task</div></div>
      <div class="tag">Open</div>
    </div>
    <div class="card rowitem">
      <div class="accent" style="background:var(--prayer)"></div>
      <div><div class="name"><span class="kind prayer">Prayer</span>2 of 5 marked</div><div class="meta">Tracker · not part of XP</div></div>
      <div class="tag">Log</div>
    </div>
  </div>
  <h2 class="block" style="margin-top:10px">Active goals</h2>
  <div class="list">
    <div class="card rowitem">
      <div class="accent" style="background:var(--sky)"></div>
      <div><div class="name"><span class="kind goal">Goal</span>Build a software business</div><div class="meta">Long · 1 of 6 milestones</div><div class="dots"><i class="on"></i><i class="now"></i><i></i><i></i><i></i><i></i></div></div>
      <div class="frac">1/6</div>
    </div>
    <div class="card rowitem">
      <div class="accent" style="background:var(--book)"></div>
      <div><div class="name"><span class="kind goal">Goal</span>Read books</div><div class="meta">Recurring · 2026 · 3 of 12</div></div>
      <div class="frac">3/12</div>
    </div>
  </div>
  <div class="btnrow">
    <div class="btn">New goal</div>
    <div class="btn ghost">Domains</div>
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
        <div class="level">8<span>Finding your rhythm</span></div>
      </div>
      <div class="xpmeta"><b>1,094</b>lifetime XP</div>
    </div>
    <div class="bar" style="margin-top:12px"><i style="width:31%"></i></div>
    <div class="barlabel"><span>Since 3 Mar 2026</span><span>Never reset</span></div>
  </article>
  <p class="quiet">Seasons end. This does not. A missed day is a gap in the line, not a debt.</p>
  <h2 class="block">Path</h2>
  <div class="rail" style="margin-top:10px">
    <div class="event"><div class="stem"><i class="now"></i><b></b></div><div class="body"><div class="when">MON 16 NOV 2026</div><div class="what">Level 8, since 12 Nov 2026</div><div class="why">161 XP to level 9 · the crossing was a milestone, once</div></div></div>
    <div class="event"><div class="stem"><i class="done"></i><b></b></div><div class="body"><div class="when">12 NOV 2026 · +40 XP</div><div class="what">Milestone · Validate the idea</div><div class="why">Goal · Build a software business</div></div></div>
    <div class="event"><div class="stem"><i class="done"></i><b></b></div><div class="body"><div class="when">2 NOV 2026</div><div class="what">Achievement · First week kept</div><div class="why">Once. The streak can break later. This stays.</div></div></div>
    <div class="gapnote">28–30 Oct 2026 · away. Streak paused. Lifetime XP unchanged.</div>
    <div class="event"><div class="stem"><i class="done"></i><b></b></div><div class="body"><div class="when">14 OCT 2026 · +8 XP</div><div class="what">Habit · Write for 25 minutes</div><div class="why">One award for that day. Not per minute.</div></div></div>
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
  <div class="stepper" aria-label="Milestones">
    <div class="step done">1</div>
    <div class="step now">2</div>
    <div class="step">3</div>
    <div class="step">4</div>
    <div class="step">5</div>
    <div class="step">6</div>
  </div>
  <div class="here">You are here · 2 · Build an MVP</div>
  <div class="rail">
    <div class="event"><div class="stem"><i class="done"></i><b></b></div><div class="body"><div class="when">1 · DONE · 12 NOV 2026</div><div class="what">Validate the idea</div><div class="why">+40 XP · recorded once</div></div></div>
    <div class="event"><div class="stem"><i class="now"></i><b></b></div><div class="body"><div class="when">2 · IN PROGRESS · PROJECT LINKED</div><div class="what">Build an MVP</div><div class="why">Project · Build the MVP · not the same object</div></div></div>
    <div class="event"><div class="stem"><i></i><b></b></div><div class="body"><div class="when">3 · WAITING</div><div class="what">First customer</div><div class="why">After “Build an MVP”</div></div></div>
    <div class="event"><div class="stem"><i></i><b></b></div><div class="body"><div class="when">4 · LATER · TARGET 5</div><div class="what">Five paying customers</div></div></div>
    <div class="event"><div class="stem"><i></i><b></b></div><div class="body"><div class="when">5 · LATER</div><div class="what">Repeatable sales</div></div></div>
    <div class="event"><div class="stem"><i></i></div><div class="body"><div class="when">6 · LINKED MONEY GOAL</div><div class="what">A steady month of revenue</div><div class="why">Points at budget objective “Monthly revenue”. Does not merge with it.</div></div></div>
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
  <div class="kind project">Project</div>
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
  <div class="milestone-title">Monday 16 November 2026</div>
  <p class="sub" style="margin-top:4px">The same records as Habit, Prayer, and your projects.</p>
  <h2 class="block">Due</h2>
  <div class="list">
    <div class="card rowitem">
      <div class="accent" style="background:var(--habit)"></div>
      <div><div class="kind habit">Habit</div><div class="name">Write for 25 minutes</div><div class="meta">Same record as the Habit tab</div></div>
      <div class="check"></div>
    </div>
    <div class="card rowitem">
      <div class="accent" style="background:var(--amber)"></div>
      <div><div class="kind quest">Quest</div><div class="name">Ship the landing page</div><div class="meta">Today only · from the landing-page task</div></div>
      <div class="check"></div>
    </div>
  </div>
  <h2 class="block">This week, from a goal</h2>
  <div class="list">
    <div class="card rowitem">
      <div class="accent" style="background:var(--sky)"></div>
      <div><div class="kind goal">Milestone</div><div class="name">Build an MVP</div><div class="meta">This week · the milestone, not a new chore</div></div>
      <div class="tag">Open</div>
    </div>
  </div>
  <h2 class="block">Prayer</h2>
  <div class="list">
    <div class="card rowitem">
      <div class="accent" style="background:var(--prayer)"></div>
      <div><div class="kind prayer">Prayer</div><div class="name">2 of 5 marked</div><div class="meta">Opens the tracker. Awards no XP.</div></div>
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
    <div class="title">Finding your rhythm</div>
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
      <div class="title">Finding your rhythm</div>
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
    <div class="mark earned">7</div>
    <div><div class="name">First week kept</div><div class="meta">Unlocked 2 Nov 2026 · seven scheduled days</div></div>
    <div class="rarity">Common</div>
  </article>
  <h2 class="block">Goal completion</h2>
  <article class="card ach" style="margin-top:8px">
    <div class="mark earned">1</div>
    <div><div class="name">Idea on paper</div><div class="meta">Unlocked 12 Nov 2026 · first milestone on a long goal</div></div>
    <div class="rarity">Uncommon</div>
  </article>
  <h2 class="block">Long-term dedication</h2>
  <article class="card ach locked" style="margin-top:8px">
    <div class="mark locked">—</div>
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
    <div class="card rowitem"><div class="accent" style="background:var(--sky)"></div><div><div class="kind goal">Goal</div><div class="name">Build a software business</div></div><div class="tag">In</div></div>
    <div class="card rowitem"><div class="accent" style="background:var(--habit)"></div><div><div class="kind habit">Habit</div><div class="name">Weekly outreach</div></div><div class="tag">In</div></div>
    <div class="card rowitem"><div class="accent" style="background:var(--peach)"></div><div><div class="kind project">Project</div><div class="name">Build the MVP</div></div><div class="tag">In</div></div>
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


SCREENS["measure"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">Knowledge &amp; Learning</div></div>
  <div class="kind goal">Goal · recurring</div>
  <div class="milestone-title">Read books</div>
  <p class="sub" style="margin-top:4px">Yearly. Each year is its own period. The goal itself stays.</p>
  <article class="card pad" style="margin-top:12px">
    <div class="row"><div class="screen-label">2026 · open</div><div class="frac">3/12</div></div>
    <div class="bar" style="margin-top:10px"><i style="width:25%"></i></div>
    <div class="barlabel"><span>3 recorded</span><span>target 12</span></div>
    <p class="sub" style="margin-top:8px">Logging a book on the shelf does not move this. You record the count.</p>
  </article>
  <h2 class="block">Earlier periods</h2>
  <div class="list">
    <div class="card rowitem"><div class="accent" style="background:var(--mint)"></div><div><div class="name">2025</div><div class="meta">9 of 12 · completed · history kept</div></div><div class="tag">Done</div></div>
    <div class="card rowitem"><div class="accent" style="background:var(--line)"></div><div><div class="name">2024</div><div class="meta">4 of 12 · missed · no XP removed</div></div><div class="tag">Kept</div></div>
  </div>
  <div class="callout">Finishing 2026 does not complete the goal and does not pay the goal’s 60 XP. That award is once, only if you end the goal, and only after you confirm.</div>
  {NAV}
</div>
"""

SCREENS["create-goal"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">Home</div></div>
  <div class="screen-label">New goal</div>
  <div class="milestone-title">What are you aiming at?</div>
  <div class="field"><div class="lbl">Title</div><div class="box">Build a software business</div></div>
  <div class="field"><div class="lbl">Domain</div>
    <div class="choice"><span class="on">Career</span><span>Knowledge</span><span>Health</span><span>Money</span></div>
  </div>
  <div class="field"><div class="lbl">Type</div>
    <div class="choice"><span>Short</span><span>Medium</span><span class="on">Long</span><span>Recurring</span><span>Open</span></div>
  </div>
  <div class="field"><div class="lbl">Measurable target</div><div class="box" style="color:var(--muted);font-weight:500">None · this goal uses milestones</div></div>
  <div class="field"><div class="lbl">First milestone</div><div class="box">Validate the idea</div></div>
  <p class="quiet">Creating this writes the goal. It does not award XP. You can undo from the goal.</p>
  <div class="btnrow"><div class="btn ghost">Cancel</div><div class="btn">Create goal</div></div>
  {NAV}
</div>
"""

SCREENS["milestones"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">Build a software business</div></div>
  <div class="screen-label">Milestones</div>
  <div class="milestone-title">Add and edit</div>
  <p class="sub" style="margin-top:4px">Order is the path. Dropped steps leave the fraction. History stays.</p>
  <article class="card" style="margin-top:12px">
    <div class="drow"><div class="handle">↕</div><div class="accent" style="background:var(--mint);height:28px"></div><div><div class="name">Validate the idea</div><div class="meta">Done · 12 Nov 2026</div></div><div class="tag">Edit</div></div>
    <div class="drow"><div class="handle">↕</div><div class="accent" style="background:var(--sky);height:28px"></div><div><div class="name">Build an MVP</div><div class="meta">In progress · after step 1</div></div><div class="tag">Edit</div></div>
    <div class="drow"><div class="handle">↕</div><div class="accent" style="background:var(--line);height:28px"></div><div><div class="name">First customer</div><div class="meta">Not started</div></div><div class="tag">Edit</div></div>
  </article>
  <div class="field"><div class="lbl">Add a milestone</div><div class="box">Five paying customers</div></div>
  <div class="field"><div class="lbl">Optional target on this step</div><div class="box" style="font-weight:500">0 recorded · target 5</div></div>
  <p class="quiet">Editing a title does not award XP. Marking done asks, then pays 40 once.</p>
  <div class="btnrow"><div class="btn">Add milestone</div></div>
  {NAV}
</div>
"""

SCREENS["create-project"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">Build an MVP</div></div>
  <div class="kind project">New project</div>
  <div class="milestone-title">How will you do it?</div>
  <div class="field"><div class="lbl">Title</div><div class="box">Build the MVP</div></div>
  <div class="field"><div class="lbl">Linked milestone</div><div class="box">Build an MVP · optional</div></div>
  <div class="field"><div class="lbl">First task</div><div class="box">Write the offer</div></div>
  <div class="field"><div class="lbl">Due</div><div class="box">No date</div></div>
  <div class="callout">A project is the work. The milestone stays the “what”. Finishing the project does not finish the milestone unless that step says so.</div>
  <div class="btnrow"><div class="btn ghost">Cancel</div><div class="btn">Create project</div></div>
  {NAV}
</div>
"""

SCREENS["create-quest"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">Today’s plan</div></div>
  <div class="kind quest">Custom quest</div>
  <div class="milestone-title">One thing you actually mean</div>
  <div class="field"><div class="lbl">Title</div><div class="box">Call one former client</div></div>
  <div class="field"><div class="lbl">Window</div>
    <div class="choice"><span class="on">Today · 16 Nov 2026</span><span>This week</span><span>This month</span></div>
  </div>
  <div class="field"><div class="lbl">Source</div><div class="box" style="font-weight:500">None · you wrote this</div></div>
  <div class="callout">Because nothing else will pay, finishing it can award 6 XP once. A quest generated from a habit or a task pays nothing extra.</div>
  <p class="quiet">Identity: custom:q1:day:2026-11-16. Tomorrow is a different quest, only if you write one.</p>
  <div class="btnrow"><div class="btn ghost">Not now</div><div class="btn">Add to today</div></div>
  {NAV}
</div>
"""

SCREENS["goal-done"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">Career &amp; Business</div></div>
  <div class="kind goal">Goal · long</div>
  <div class="milestone-title">Build a software business</div>
  <div class="stepper">
    <div class="step done">1</div><div class="step done">2</div><div class="step done">3</div>
    <div class="step done">4</div><div class="step done">5</div><div class="step done">6</div>
  </div>
  <p class="here">Every milestone that counts is done.</p>
  <div class="scrim" style="top:240px">
    <article class="card moment">
      <div class="screen-label">Confirm</div>
      <h3 style="font-family:Outfit,sans-serif;font-size:22px;font-weight:700;line-height:28px">Mark the goal complete?</h3>
      <p class="sub" style="margin-top:8px">This records +60 XP once. It is not the sum of the milestones. Leave it open if you are not finished.</p>
      <div class="btnrow"><div class="btn ghost">Not yet</div><div class="btn">Complete goal</div></div>
    </article>
  </div>
</div>
"""

SCREENS["undo"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">Home</div></div>
  <div class="screen-label">Monday 16 November 2026</div>
  <div class="milestone-title">Write for 25 minutes</div>
  <article class="card rowitem" style="margin-top:12px">
    <div class="accent" style="background:var(--habit)"></div>
    <div><div class="kind habit">Habit</div><div class="name">Marked done</div><div class="meta">Also today’s quest · +8 XP open</div></div>
    <div class="check on"></div>
  </article>
  <div class="scrim" style="top:220px">
    <article class="card moment">
      <div class="screen-label">Undo</div>
      <h3 style="font-family:Outfit,sans-serif;font-size:22px;font-weight:700;line-height:28px">Unmark this day?</h3>
      <p class="sub" style="margin-top:8px">The habit, the quest for 16 Nov 2026, and the XP stay in agreement. The +8 is reversed with a new ledger row. It is not deleted. You can complete the day again later.</p>
      <div class="btnrow"><div class="btn ghost">Keep</div><div class="btn">Unmark</div></div>
    </article>
  </div>
</div>
"""

SCREENS["grok"] = f"""
<div class="phone">
  <div class="backrow"><div class="iconbtn">&#xe138;</div><div class="kicker">Home</div></div>
  <div class="screen-label">Grok · in the app</div>
  <div class="milestone-title">Ask</div>
  <article class="card pad" style="margin-top:12px">
    <div class="speak">I want to learn React in 3 months.</div>
  </article>
  <article class="card pad proposal" style="margin-top:10px">
    <div class="screen-label">Proposal · nothing saved</div>
    <div class="kind goal" style="margin-top:8px">Goal</div>
    <div class="name" style="font-weight:700;margin-top:4px">Learn React</div>
    <p class="sub">Knowledge &amp; Learning · medium · not a counted target</p>
    <p class="sub" style="margin-top:6px">1 · Say what “learn” means<br>2 · Build a small thing<br>3 · Use it on real work</p>
    <p class="sub" style="margin-top:6px">Suggested habit · three short practices a week. No XP until something is completed.</p>
    <div class="btnrow"><div class="btn ghost">Not now</div><div class="btn">Confirm</div></div>
  </article>
  <p class="quiet">Confirm calls RUHH. Grok does not write the database and does not choose the XP.</p>
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
