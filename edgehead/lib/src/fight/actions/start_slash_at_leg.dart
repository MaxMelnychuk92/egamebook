import 'package:edgehead/fractal_stories/action.dart';
import 'package:edgehead/fractal_stories/actor.dart';
import 'package:edgehead/fractal_stories/anatomy/body_part.dart';
import 'package:edgehead/fractal_stories/context.dart';
import 'package:edgehead/fractal_stories/pose.dart';
import 'package:edgehead/fractal_stories/simulation.dart';
import 'package:edgehead/fractal_stories/situation.dart';
import 'package:edgehead/fractal_stories/storyline/storyline.dart';
import 'package:edgehead/fractal_stories/world_state.dart';
import 'package:edgehead/src/fight/actions/start_slash_at_body_part.dart';
import 'package:edgehead/src/fight/common/combat_command_path.dart';
import 'package:edgehead/src/fight/common/defense_situation.dart';
import 'package:edgehead/src/fight/common/start_defensible_action.dart';
import 'package:edgehead/src/fight/common/weapon_as_object2.dart';
import 'package:edgehead/src/fight/slash/slash_defense/slash_defense_situation.dart';
import 'package:edgehead/src/fight/slash/slash_situation.dart';
import 'package:edgehead/src/predetermined_result.dart';

class StartSlashAtLeg extends StartDefensibleActionBase {
  static final StartSlashAtLeg singleton = StartSlashAtLeg();

  static const String className = "StartSlashAtLeg";

  @override
  CombatCommandType get combatCommandType => CombatCommandType.limbs;

  @override
  String get helpMessage => "Legs provide mobility. A downed opponent is much "
      "easier to deal with.";

  @override
  String get name => className;

  @override
  bool get rerollable => true;

  @override
  Resource get rerollResource => Resource.stamina;

  @override
  String get rollReasonTemplate => "will <subject> hit the leg?";

  @override
  bool get shouldShortCircuitWhenFailed => false;

  @override
  void applyShortCircuit(Actor actor, Simulation sim, WorldStateBuilder world,
      Storyline storyline, Actor enemy, Situation mainSituation) {
    throw StateError("This action doesn't short-circuit on failure.");
  }

  @override
  void applyStart(Actor a, Simulation sim, WorldStateBuilder world, Storyline s,
      Actor enemy, Situation mainSituation) {
    a.report(
        s,
        "<subject> swing<s> {${weaponAsObject2(a)} |}at "
        "<objectOwner's> <object>",
        object: Entity(name: 'leg'),
        objectOwner: enemy,
        actionThread: mainSituation.id,
        isSupportiveActionInThread: true);
  }

  @override
  DefenseSituation defenseSituationBuilder(Actor a, Simulation sim,
      WorldStateBuilder w, Actor enemy, Predetermination predetermination) {
    return createSlashDefenseSituation(
        w.randomInt(), a, enemy, predetermination);
  }

  @override
  String getCommandPathTail(ApplicabilityContext context, Actor target) =>
      "slash at <objectPronoun's> leg";

  @override
  bool isApplicable(Actor a, Simulation sim, WorldState w, Actor enemy) =>
      _isApplicableBase(a, sim, w, enemy) && _getAllLegs(enemy).length >= 2;

  @override
  Situation mainSituationBuilder(
      Actor a, Simulation sim, WorldStateBuilder w, Actor enemy) {
    final leg = _getTargetLeg(enemy, w.time.millisecondsSinceEpoch);

    return createSlashSituation(w.randomInt(), a, enemy,
        designation: leg.designation);
  }

  @override
  ReasonedSuccessChance successChanceGetter(
      Actor a, Simulation sim, WorldState w, Actor enemy) {
    final leg = _getTargetLeg(enemy, w.time.millisecondsSinceEpoch);
    return computeStartSlashAtBodyPartGenerator(leg, a, sim, w, enemy);
  }

  static Iterable<BodyPart> _getAllLegs(Actor target) {
    assert(
        target.anatomy.isHumanoid,
        "This function currently assumes that legs are the only "
        "body parts providing mobility.");

    return target.anatomy.allParts.where((part) =>
        part.function == BodyPartFunction.mobile && part.isAliveAndActive);
  }

  static BodyPart _getTargetLeg(Actor enemy, int time) {
    final legs = _getAllLegs(enemy).toList(growable: false);
    assert(legs.isNotEmpty);

    // Must be consistent, so no random (not even stateful random)
    return legs[(time ~/ 1300) % legs.length];
  }

  static bool _isApplicableBase(
          Actor a, Simulation sim, WorldState w, Actor enemy) =>
      !a.isOnGround &&
      // This is here because we currently don't have a way to dodge
      // a thrust while on ground. TODO: fix and remove
      !enemy.isOnGround &&
      !a.anatomy.isBlind &&
      a.currentWeapon.damageCapability.isSlashing &&
      // Only allow leg attacks when enemy has worse than combat stance.
      enemy.pose < Pose.combat &&
      !enemy.anatomy.hasCrippledLegs;
}

class StartSlashAtRemainingLeg extends StartSlashAtLeg {
  static const String className = "StartSlashAtRemainingLeg";

  static final StartSlashAtRemainingLeg singleton = StartSlashAtRemainingLeg();

  @override
  String get name => className;

  @override
  String getCommandPathTail(ApplicabilityContext context, Actor target) =>
      "slash at <objectPronoun's> remaining leg";

  @override
  bool isApplicable(Actor a, Simulation sim, WorldState w, Actor enemy) =>
      StartSlashAtLeg._isApplicableBase(a, sim, w, enemy) &&
      // This action assumes we're targeting just one of (several?) arms.
      StartSlashAtLeg._getAllLegs(enemy).length == 1;
}
