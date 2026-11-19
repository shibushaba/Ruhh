#!/usr/bin/env python3
"""Expected and example level curves for the provisional RUHH awards.

Not app code. Does not award XP. Prints a table and writes a chart
next to the Phase 1 frames.

Awards (provisional): habit 8, custom quest 6, milestone 40, goal 60.
Project 24 is not used: in these profiles a milestone already pays.
Prayer, books, movies, and transactions pay nothing.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

HABIT = 8
QUEST = 6
MILESTONE = 40
GOAL = 60
WINDOWS = (30, 90, 365, 730)
MILESTONE_DAYS = (90, 180, 270, 360, 450, 540, 630, 720)
GOAL_DAY = 400
SEED = 16


def threshold(level: int) -> int:
    if level <= 1:
        return 0
    return math.floor(50 * ((level - 1) ** 1.55))


def level_for(xp: int) -> int:
    level = 1
    while threshold(level + 1) <= xp:
        level += 1
        if level > 80:
            break
    return level


def title_for(level: int) -> str:
    if level <= 3:
        return "Beginning"
    if level <= 6:
        return "Showing up"
    if level <= 11:
        return "Finding your rhythm"
    if level <= 19:
        return "In motion"
    if level <= 34:
        return "The long view"
    return "Still here"


def extras_on(day: int, rich: bool) -> int:
    if not rich:
        return 0
    xp = 0
    if day in MILESTONE_DAYS:
        xp += MILESTONE
    if day == GOAL_DAY:
        xp += GOAL
    if day % 30 == 0:
        xp += QUEST
    return xp


def expected_xp(days: int, habits: int, rate: float, rich: bool) -> int:
    habit_xp = days * habits * rate * HABIT
    extra = sum(extras_on(day, rich) for day in range(1, days + 1))
    return int(round(habit_xp + extra))


def example_xp(days: int, habits: int, rate: float, rich: bool, seed: int) -> int:
    rng = random.Random(seed)
    xp = 0
    for day in range(1, days + 1):
        for _ in range(habits):
            if rng.random() < rate:
                xp += HABIT
        xp += extras_on(day, rich)
    return xp


PROFILES = (
    ("A", "One daily habit", 1, 0.80, False),
    ("B", "Three daily habits", 3, 0.70, False),
    ("C", "Five daily habits", 5, 0.60, False),
    ("D", "Three habits, milestones, one goal", 3, 0.70, True),
)


def series(habits: int, rate: float, rich: bool, seed: int) -> list[int]:
    rng = random.Random(seed)
    xp = 0
    out = []
    for day in range(1, 731):
        for _ in range(habits):
            if rng.random() < rate:
                xp += HABIT
        xp += extras_on(day, rich)
        out.append(xp)
    return out


def write_chart(path: Path) -> None:
    colors = {"A": "#94A3B8", "B": "#4ADE80", "C": "#38BDF8", "D": "#FBBF24"}
    width, height = 880, 520
    left, right, top, bottom = 64, 36, 48, 46
    plot_w, plot_h = width - left - right, height - top - bottom
    ymax = 18000

    def xy(day: int, xp: int) -> tuple[float, float]:
        x = left + (day - 1) / 729 * plot_w
        y = top + (1 - min(xp, ymax) / ymax) * plot_h
        return x, y

    lines = []
    for key, _label, habits, rate, rich in PROFILES:
        pts = series(habits, rate, rich, SEED + ord(key))
        # One point per week keeps the file small and the line honest.
        coords = [xy(day, pts[day - 1]) for day in range(1, 731, 7)]
        coords.append(xy(730, pts[-1]))
        d = " ".join(f"{x:.1f},{y:.1f}" for x, y in coords)
        lines.append(
            f'<polyline fill="none" stroke="{colors[key]}" stroke-width="2" points="{d}"/>'
        )
    guides = []
    for level in (5, 10, 20, 35):
        _x, y = xy(1, threshold(level))
        guides.append(
            f'<line x1="{left}" y1="{y:.1f}" x2="{width - right}" y2="{y:.1f}" stroke="#383838"/>'
            f'<text x="{width - right - 4}" y="{y - 4:.1f}" fill="#949494" font-size="11" text-anchor="end">L{level}</text>'
        )
    legend = []
    for i, (key, label, _h, _r, _rich) in enumerate(PROFILES):
        lx = 430 + (i % 2) * 210
        ly = 16 + (i // 2) * 16
        legend.append(
            f'<line x1="{lx}" y1="{ly}" x2="{lx + 16}" y2="{ly}" stroke="{colors[key]}" stroke-width="2"/>'
            f'<text x="{lx + 20}" y="{ly + 4}" fill="#F5F5F5" font-size="11">{key} · {label}</text>'
        )
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">
  <rect width="100%" height="100%" fill="#050505"/>
  <text x="{left}" y="28" fill="#F5F5F5" font-family="DM Sans, sans-serif" font-size="16" font-weight="700">Example lifetime XP over 730 days</text>
  <rect x="{left}" y="{top}" width="{plot_w}" height="{plot_h}" fill="#141414" stroke="#383838"/>
  {''.join(guides)}
  {''.join(lines)}
  <text x="{left}" y="{height - 16}" fill="#949494" font-size="12">Day 1</text>
  <text x="{width - right}" y="{height - 16}" fill="#949494" font-size="12" text-anchor="end">Day 730</text>
  <text x="16" y="{top + 12}" fill="#949494" font-size="11">18k</text>
  <text x="16" y="{top + plot_h}" fill="#949494" font-size="11">0</text>
  {''.join(legend)}
</svg>'''
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(svg, encoding="utf-8")


def main() -> None:
    print("| Profile | Window | Expected XP | Level | Title | Example XP | Example level |")
    print("| --- | --- | ---: | ---: | --- | ---: | ---: |")
    for key, _label, habits, rate, rich in PROFILES:
        for days in WINDOWS:
            exp = expected_xp(days, habits, rate, rich)
            ex = example_xp(days, habits, rate, rich, SEED + ord(key))
            lv = level_for(exp)
            print(
                f"| {key} | {days} days | {exp} | {lv} | {title_for(lv)} | {ex} | {level_for(ex)} |"
            )
    chart = Path(__file__).resolve().parents[1] / "designs" / "xp-balance.svg"
    try:
        write_chart(chart)
        print(f"chart {chart}")
    except Exception as exc:  # noqa: BLE001 — docs tool, report and continue
        print(f"chart skipped: {exc}")


if __name__ == "__main__":
    main()
