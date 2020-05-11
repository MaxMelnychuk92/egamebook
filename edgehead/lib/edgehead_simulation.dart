import 'package:edgehead/edgehead_director.dart';
import 'package:edgehead/fractal_stories/actor.dart';
import 'package:edgehead/fractal_stories/actor_score.dart';
import 'package:edgehead/fractal_stories/item.dart';
import 'package:edgehead/fractal_stories/items/weapon_type.dart';
import 'package:edgehead/fractal_stories/planner_recommendation.dart';
import 'package:edgehead/fractal_stories/pose.dart';
import 'package:edgehead/fractal_stories/room.dart';
import 'package:edgehead/fractal_stories/simulation.dart';
import 'package:edgehead/fractal_stories/situation.dart';
import 'package:edgehead/fractal_stories/storyline/storyline.dart';
import 'package:edgehead/src/room_roaming/room_roaming_situation.dart';
import 'package:edgehead/stateful_random/stateful_random.dart';
import 'package:edgehead/writers_input.compiled.dart';

import 'edgehead_ids.dart';

const String carelessMonsterFoldFunctionHandle = "carelessMonster";

const String normalFoldFunctionHandle = "normal";

final Actor edgeheadDirector = Actor.initialized(
  directorId,
  StatefulRandom(directorId + ~42).next,
  "DIRECTOR",
  isDirector: true,
);

final Situation edgeheadInitialSituation =
    RoomRoamingSituation.initialized(100, _preStartBook, false);

/// Trader Joseph's son.
final Actor edgeheadLeroy = Actor.initialized(
  leroyId,
  StatefulRandom(~leroyId).next,
  "Leroy",
  nameIsProperNoun: true,
  pronoun: Pronoun.HE,
  currentRoomName: 'bleeds_trader_hut',
  currentWeapon: Item.weapon(234234, WeaponType.dagger,
      adjective: "long", name: "dagger", firstOwnerId: leroyId),
  currentShield: Item.weapon(1188984, WeaponType.shield,
      adjective: "peasant", firstOwnerId: leroyId),
);

final Actor edgeheadPlayer = Actor.initialized(
  playerId,
  StatefulRandom(~playerId).next,
  "Aren",
  isSurvivor: true,
  nameIsProperNoun: true,
  isPlayer: true,
  pronoun: Pronoun.I,
  constitution: 2,
  dexterity: 150,
  stamina: 3,
  initiative: 1000,
  poseMax: Pose.combat,
  currentRoomName: _preStartBook.name,
);

final Simulation edgeheadSimulation = Simulation(
    _rooms, allApproaches, _foldFunctions, edgeheadDirectorRuleset, allInks);

final Actor edgeheadTamara = Actor.initialized(
  tamaraId,
  StatefulRandom(~tamaraId).next,
  "Tamara",
  nameIsProperNoun: true,
  pronoun: Pronoun.SHE,
  // Slightly quicker than the player but not quicker than the first goblin.
  initiative: 1500,
  currentRoomName: _preStartBook.name,
  followingActorId: playerId,
  currentWeapon: Item.weapon(2342341, WeaponType.sword,
      adjective: "mercenary", firstOwnerId: tamaraId),
);

final Map<String, FoldFunction> _foldFunctions = {
  normalFoldFunctionHandle: normalFoldFunction,
  carelessMonsterFoldFunctionHandle: carelessMonsterFoldFunction,
};

/// This is a special room that starts every adventure.
///
/// Writers should create an [Approach] from this room to their first meaningful
/// room. For example:
///
///     APPROACH: $my_adventure_start FROM $pre_start_book
///     COMMAND: <implicit>
///     DESCRIPTION: N/A
final _preStartBook = Room(
  "pre_start_book",
  (c) => throw StateError("pre_start_book is never visited, only used for "
      "approaching other rooms"),
  (c) => throw StateError("pre_start_book isn't to be revisited"),
  null,
  null,
  isSynthetic: true,
  positionX: 0,
  positionY: 0,
  mapName: "<NOT VISIBLE>",
  hint: "This should never be visible.",
);

final List<Room> _rooms = List<Room>.from(allRooms)
  ..addAll([_preStartBook, endOfRoam]);

/// Lesser self-worth than normal combine function as monsters should
/// kind of carelessly attack to make fights more action-packed.
num carelessMonsterFoldFunction(ActorScoreChange scoreChange) =>
    scoreChange.selfPreservation +
    // Monster AI cares about action-packed combat.
    scoreChange.varietyOfAction -
    // Twice the weight of hurting the enemy.
    2 * scoreChange.enemy;

num normalFoldFunction(ActorScoreChange scoreChange) =>
    scoreChange.selfPreservation +
    scoreChange.teamPreservation -
    scoreChange.enemy;
