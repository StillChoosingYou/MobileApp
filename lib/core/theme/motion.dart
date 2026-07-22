import 'package:flutter/material.dart';

/// The app's motion system — durations, curves, and stagger timing in one
/// place, so every screen animates consistently and there's exactly one
/// spot to retune the feel later.
///
/// Loosely follows Material Design 3's motion guidance: short, purposeful
/// durations; easing that decelerates into rest (nothing bounces or
/// overshoots, which reads as playful rather than professional for a
/// campus records system); nothing that outlasts its welcome or makes the
/// person wait on a page they've already committed to opening.
class AppMotion {
  AppMotion._();

  // ── Durations ────────────────────────────────────────────────────────
  /// Micro-feedback: a tap state, an icon toggling. Fast enough to read as
  /// instantaneous.
  static const Duration fast = Duration(milliseconds: 150);

  /// The default for most transitions: page changes, cards fading in,
  /// content swapping after a load.
  static const Duration standard = Duration(milliseconds: 250);

  /// Reserved for the few moments worth lingering on — the Digital ID
  /// "materializing," a receipt confirming. Long enough to notice, still
  /// short enough not to feel slow.
  static const Duration emphasized = Duration(milliseconds: 450);

  // ── Curves ───────────────────────────────────────────────────────────
  /// The default curve for anything entering or changing.
  static const Curve standardCurve = Curves.easeOutCubic;

  /// A slightly more pronounced decelerate, for the emphasized moments.
  static const Curve emphasizedCurve = Curves.easeOutQuint;

  // ── Stagger (list/grid entrance) ────────────────────────────────────
  /// Per-item delay for staggered entrance animations (role cards, stat
  /// tiles, chat bubbles). Small enough that a 6-item grid finishes in a
  /// quarter-second, capped so item #40 in a long list doesn't wait
  /// several seconds for its turn.
  static const Duration staggerStep = Duration(milliseconds: 40);
  static const int staggerCap = 10;

  static Duration staggerDelayFor(int index) =>
      staggerStep * (index > staggerCap ? staggerCap : index);

  // ── Accessibility ────────────────────────────────────────────────────
  /// True when the person has "reduce motion" on at the OS level
  /// (Settings → Accessibility, on every platform this app targets).
  /// Every animation built through this file collapses to an instant (or
  /// near-instant) transition when this is true — motion becomes optional
  /// decoration, never the only way information reaches the screen.
  static bool reduceMotion(BuildContext context) => MediaQuery.of(context).disableAnimations;
}
