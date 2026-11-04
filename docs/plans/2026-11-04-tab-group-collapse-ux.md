# Tab Group Collapse UX

Requirement: collapsed tab groups read as an instant vanish — no animation, the
chevron only appears on hover (never in the top strip), and a folded heading
gives no count or hint of what is inside. Redesign so the state is obvious.

## Design (approved, option A)

- `Browser.toggleTabGroup` / `foldAllGroups` flip `collapsed` inside
  `withAnimation(Motion.settle)` (nil under Reduce Motion, via Motion).
- `GroupHeading` (all three forms: sidebar, top strip, icon column):
  - chevron always visible, rotates with `Motion.settle`;
  - collapsed heading wears a filled tile background, expanded stays clear;
  - collapsed heading shows a count capsule with the hidden tab count;
  - when the active tab is inside a collapsed group, a dot marks the heading
    and the tooltip/accessibility value say so.
- Member rows fade via `.transition(.opacity)` as they leave/return.
- New testable helpers on `Browser`: `hiddenTabCount(in:)`,
  `groupContainsActive(_:)`.

## Tasks

1. Test: `Tests/SearchTests/TabGroupCollapseTests.swift` — hidden count and
   active membership for collapsed/expanded groups. Run, expect failure
   (helpers missing). `swift test --filter TabGroupCollapseTests`
2. Implement helpers + animated toggle in `Browser.swift`. Test passes.
3. Heading redesign in `TabGroups.swift` (chevron/count capsule/active dot/
   tile/a11y). Wire row transitions in `Side.swift` + `TabBar.swift`.
4. Full suite: `swift test` — green except the two known baseline failures
   (`ExtensionPopupSizingTests.testFlexibleDelayedAndOversizedContent`,
   `SidebarPressTests.testOtherButtonsDoNotSelectOnPress`, pre-existing on
   origin/main).
5. Push `feature/tab-group-collapse-ux`, open PR, remove worktree.
