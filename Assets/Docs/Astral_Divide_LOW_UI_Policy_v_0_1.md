# Astral Divide LOW UI Policy v0.1

## Purpose

This document defines the role of `LOW` render quality in Astral Divide.

`HIGH` is the primary development and recommended play environment.  
`MIDDLE` is a reduced but still presentation-conscious mode for smaller or weaker environments.  
`LOW` is not intended to preserve the full visual experience of `HIGH`.

`LOW` is defined as a compatibility mode whose primary goal is:

- Keep the game operable.
- Keep text readable.
- Prevent progression blockers caused by display constraints.

In short:

`LOW = minimal playable compatibility mode`

## Current Decision

At the present project stage, full `LOW` polish is not a priority.

Reason:

- Main story and gameplay UI are not fully implemented yet.
- A full LOW redesign would affect multiple future screens.
- Doing a complete LOW pass now would likely create rework later.

Therefore, current policy is:

- Define the LOW concept now.
- Do not fully redesign LOW yet.
- Prioritize core game development first.

## Practical Rules For LOW

When LOW-specific UI work is eventually performed, it should follow these principles:

- Prefer readability over presentation fidelity.
- Reduce decorative elements freely.
- Remove or compress subtitles, footers, and auxiliary text when needed.
- Avoid forcing HIGH-density layouts into smaller screens.
- Favor stable navigation and visible selection state over visual symmetry.
- Accept simpler structure if it prevents layout breakage.

## Current Status

Current LOW behavior in `MMM` and `SDS` should be treated as provisional.

This means:

- LOW is allowed to be less polished than HIGH and MIDDLE for now.
- Only severe usability failures should be fixed immediately.
- Broad LOW refinement should happen after more of the main game UI exists.

## Future Work Trigger

A dedicated LOW polish phase should begin after one or more of the following become true:

- Main story UI direction is stable.
- Combat or scenario UI begins relying on finalized presentation rules.
- Multiple screens need consistent LOW-mode behavior.

At that point, LOW should be revisited as a cross-screen UI policy task, not as isolated screen-by-screen patchwork.
