part of spaceship;

/**
 * [CombatMove] defines a possibility (choice) for the player / AI to perform
 * with a specified system. E.g. fire a gun, redistribute energy from an engine,
 * use the tractor beam. 
 * 
 * The most general characteristics of a move are defined by static variables
 * ([name], [needsTarget]) and methods ([update]). But specific variants of the
 * move (i.e. firing from a concrete gun on a concrete ship) are implemented
 * by creating a new instance and adding it to the [ShipSystem]'s 
 * [availableMoves] list. When a [CombatMove] is started, it is referenced 
 * by the [ShipSystem]'s [currentMove] variable and updated on each turn.
 * 
 * When finished, the CombatMove can either [autoRepeat], or it stops (the
 * [currentMove] variable is set to [:null:]).
 * 
 * Class [CombatMove] can be extended (e.g. by [FireGun] or [RepairSystem])
 * for more readable code.
 */
abstract class CombatMove {
  CombatMove(this.system) {
  }
  
  /// The system that performs this move. Ex.: the laser gun performing this
  /// laser shot.
  final ShipSystem system;
  /// The (optional) target ship.
  Spaceship targetShip;
  /// The (optional) exact target system.
  ShipSystem targetSystem;
  
  /// Whether this move is currently available to the actor. Use this to
  /// hide options from the player and then add them as a form of progression.
  // @saveable
  static bool available = true; // TODO: saveable!!!?
  
  /// The unique name of this particular type of move.
  static final String name = "undefined move";
  get instanceName => name; // Dart cannot access static member, so we need to copy
  
  /// The text of the choice presented to player.
  String get commandText;  // fire weapon at <object>
  
  /// Only reported for player (TODO: or other people on same ship) when he
  /// starts programming the ship computer to do something.
  void reportSettingUp() {
    var pilot = system.spaceship.pilot;
    if (pilot == null || !pilot.isPlayer) {
      throw new StateError("reportSettingUp should not have been called since "
          "this spaceship's pilot is null or is not player");
    }
    storyline.add(stringSettingUp, subject: pilot, object: system,
        time: system.spaceship.currentCombat.timeline.time);
  }
  String get stringSettingUp => "<subject> start<s> programming the "
                                "${system.name} to $commandText";
  
  /// Reported when the computer/system starts the sequence.
  void reportStarting() => _report(stringStarting); 
  String stringStarting = "<subject> {initiate|start}<s> the $name";
  
  /// Ex.: <subject> <is> firing at <object> 
  // YAGNI?
  //String gerundString;
  
  /// Reported when an already started CombatMove ceases to be eligible to
  /// continue (e.g. targetShip disappears, goes out of range, etc.).
  void reportCannotContinue() => _report(stringCannotContinue);  
  String stringCannotContinue = ""; // <subject> is no longer able to fire at <object>
  
  /// Reported when the move is successfully finished.
  void reportSuccess() => _report(stringSuccess);
  String stringSuccess = "<subject> successfully finish<es> $name";
  void onSuccess() {}
  
  /// Reported when the move finished with failure.
  void reportFailure() => _report(stringFailure); 
  String stringFailure = "<subject> failed to perform $name";
  void onFailure() {}

  /// Reported when the move is going for another round.
  void reportAutoRepeat() => _report(stringAutoRepeat); 
  String stringAutoRepeat = "";   // <subject> goes for another round of
  
  void reportStop() => _report(stringStop);
  String get stringStop => "<subject> stop<s> to $commandText";
  void stop() {
    reportStop();
    currentTimeToFinish = null;
    currentTimeToSetup = null;
    system.currentMove = null;
  }
  
  void _report(String str, {Entity object, bool positive: false, 
    bool negative: false}) {
    if (str == null || str == "") return;
    Actor owner;
    Actor subject;
    if (system.spaceship.pilot.isPlayer) {
      subject = system.spaceship.pilot;
      owner = null;
    } else {
      subject = system;
      owner = system.spaceship;
    }
    if (object == null) {
      object = _getTargetObject();
    }
    storyline.add(str, subject: subject, owner: owner, object: object, 
        positive: positive, negative: negative, 
        time: system.spaceship.currentCombat.timeline.time);
  }
  
  Entity _getTargetObject() {
    Entity object = targetSystem;
    if (object is Hull) {
      // When failing to hit hull, what we really miss is the ship.
      object = (object as Hull).spaceship;
    }
    if (object == null) {
      object = targetShip;
    }
    return object;
  }
  
  /// Whether this combat move needs a target ship that is alive.
  final bool needsTargetShip = true;
  /// Whether this combat move needs a target system that is alive.
  final bool needsTargetSystem = true;
  
  /// Whether the move is supposed to automatically renew itself after each
  /// run.
  final bool autoRepeat = false;
  
  /// Is the move currently eligible to be carried out?
  bool isEligible({Spaceship targetShip, ShipSystem targetSystem}) {
    if (needsTargetShip) {
      if (targetShip == null && this.targetShip != null) {
        targetShip = this.targetShip;
      }
      if (targetShip == null || !targetShip.isAliveAndActive) return false;
    }
    if (!needsTargetShip && needsTargetSystem) {
      if (targetSystem == null && this.targetSystem != null) {
        targetSystem = this.targetSystem;
      }
      if (targetSystem == null || !targetSystem.isAliveAndActive) return false;
    }
    if (!available) return false;
    if (!system.isAlive) return false;
    if (!system.spaceship.isAliveAndActive) return false;
    return true;
  }
  
  /// Can the move continue?
  bool canContinue() => isEligible();
  
  /// Can be overridden with more involved mathemathics (incl. things like
  /// maneuverability of targetShip, etc.).
  num calculateSuccessChance({Spaceship targetShip, ShipSystem targetSystem}) => 
        defaultSuccessChance;
  final num defaultSuccessChance = 1.0;
  
  /**
   * Runs just after the CombatMove gets picked by the player. Can just update
   * some variable, or can create a list of choices.
   */
  void start() {}
  
  /// The time it takes for a pilot to setup the combat move on the console.
  int timeToSetup;
  int currentTimeToSetup;
  
  /// The time it takes for the combat to finish (e.g. for a laser gun to fire).
  int timeToFinish;
  int currentTimeToFinish;
  
  /// The timeline from start of performing to finish (e.g. charging to fire).
  // Timeline timeline <-- YAGNI
  
  /**
   * Goes one tick in the lifetime of the CombatMove. Decreases 
   * [currentTimeToSetup] or [currentTimeToFinish], depending on state of the
   * move (setup phase or perform phase).
   */
  void update() {
    if ((currentTimeToSetup != null || currentTimeToFinish != null) &&
        !canContinue()) {
      reportCannotContinue();
      currentTimeToSetup = currentTimeToFinish = null;
    }
    
    if (currentTimeToSetup != null) {
      if (currentTimeToSetup == timeToSetup && system.spaceship.pilot != null
          && system.spaceship.pilot.isPlayer) {
        // only report setting up for player (TODO: + other people on same ship)
        reportSettingUp();
      }
      --currentTimeToSetup;
      if (currentTimeToSetup <= 0) {
        currentTimeToSetup = null;
        currentTimeToFinish = timeToFinish;
      }
      return;
    }
    
    if (currentTimeToFinish == null) return;
    if (currentTimeToFinish == timeToFinish) reportStarting();
    // delay if system is underpowered proportionally to the power input
    if (Randomly.saveAgainst(system.powerInput.percentage)) {
      currentTimeToFinish -= 1;
    }
    if (currentTimeToFinish == 0) {
      if (Randomly.saveAgainst(calculateSuccessChance())) {
        reportSuccess();
        onSuccess();
      } else {
        reportFailure();
        onFailure();
      }
      if (autoRepeat) {
        reportAutoRepeat();
        currentTimeToFinish = timeToFinish;
      } else {
        currentTimeToFinish = null;
      }
    }
  }
}

/**
 * Lets player/AI fire at a given [ShipSystem] (hull by default).
 */
class FireGun extends CombatMove {
  FireGun(ShipSystem system) : super(system) {
    // it is safe to assume the [system] is a weapon in this subclass
    weapon = system as Weapon;
  }

  /// Copy of [system], but because this is [FireGun], its safe to cast it
  /// as a weapon
  Weapon weapon;
  
  final bool needsTargetShip = true;
  final bool needsTargetSystem = true;
  
  bool autoRepeat = false;
  
  int timeToSetup = 4;
  int timeToFinish = 3;
  
  static final String name = "fire gun";
  String get commandText => "fire";

  @override
  void reportSettingUp() {
    var pilot = system.spaceship.pilot;
    if (pilot == null || !pilot.isPlayer) {
      throw new StateError("reportSettingUp should not have been called since "
          "this spaceship's pilot is null or is not player");
    }
    
    storyline.add("<subject> {grab<s>|take<s>|take<s> hold of} <owner's> "
        "controls", subject: pilot, owner: system, 
        time: system.spaceship.currentCombat.timeline.time);
    storyline.add("<subject> {start<s> "
        "{aiming at|taking aim at|fixing on|zeroing in on}|"
        "begin<s> to {{take |}aim at|fix on|zero in on}} <object>",
        subject: pilot, object: targetShip,
        time: system.spaceship.currentCombat.timeline.time);
  }
  
  String get stringStarting => null; 
//      "<subject's> ${system.name} {begins|starts} "
//                               "charging";
                               
  void reportSuccess() {
//    storyline.add("<subject's> ${system.name} fires at <object>",
//                  subject: system.spaceship, object: targetShip);
  }
  
  void onSuccess() {
    _hit(targetSystem);
  }
  
  void _hit(ShipSystem targetSystem) {
    var damage = weapon.damage;
    if (damage == 0) return;
    var shield = targetSystem.spaceship.shield;
    if (shield != null && shield.isAliveAndActive && shield.sp.isNonZero) {
      if (!Randomly.saveAgainst(weapon.shieldPenetration)) {
        _report("<owner's> <subject> {drill<s> into|hit<s>} <object's> shield",
                positive: true);
        // better = "<subject-owner's> <subject> {drill<s> into|hit<s>} <object-owner's> <object>"
        if (damage > shield.sp.value) {
          // Rest of energy goes to hp damage
          damage -= shield.sp.value;
          shield.sp.value = 0;
          // TODO: report?
        } else {
          shield.sp.value -= weapon.damage;
          damage = 0;
        }
      } else {
        // TODO: better
        storyline.add("the ${weapon.projectileName} "
            "goes {right|} through <object's> shield",
            subject: system.spaceship, object: targetSystem.spaceship, 
            positive: true,
            time: system.spaceship.currentCombat.timeline.time);
      }
    }
    if (damage > 0) {
      _report("<owner's> <subject> {hit<s>|succeed<s> to hit|"
          "successfully hit<s>} <object>", object: targetSystem,
          positive: true);
      targetSystem.hp.value -= damage;
    }
  }
  
  void reportFailure() {
    _report("<owner's> <subject> {fail<s> to hit|miss<es>|go<es> wide of} "
        "<object>", negative: true);
  }
  
  void onFailure() {
    if (!(targetSystem is Hull)) {
      // when targetting a specific system, it's possible to miss that one
      // but still hit the hull (but with half the probability)
      if (Randomly.saveAgainst(
              calculateSuccessChance(targetSystem: targetShip.hull) / 2.0)) {
        _hit(targetShip.hull);
      } else {
        _report("<subject> {miss<es>|go<es> wide of} <object>, too", 
            object: targetShip, negative: true);
      }
    }
  }
  
  bool isEligible({Spaceship targetShip, ShipSystem targetSystem}) {
    if (!super.isEligible(targetShip: targetShip, targetSystem: targetSystem)) {
      return false;
    }
    if (system.powerInput.value != system.powerInput.max) return false;
    if (targetSystem != null && !targetSystem.isOutsideHull) return false;
    return true;
  }
  
  num calculateSuccessChance({Spaceship targetShip, ShipSystem targetSystem}) {
    if (targetSystem == null) targetSystem = this.targetSystem;
    if (targetSystem == null && targetShip != null) {
      targetSystem = targetShip.hull;
    }
    if (targetSystem == null) return 0.0;  // No target, no luck.
    var chance = defaultSuccessChance * targetSystem.exposedFactor *
                 weapon.accuracyModifier;
    chance -= targetSystem.spaceship.maneuverability / 100;
    if (chance < 0) return 0.0;
    return chance;
  }
  num defaultSuccessChance = 0.8;
  
  void _createChoiceForTargetSystem(ShipSystem targetSystem) {
    String probability = Randomly.humanStringifyProbability(
        calculateSuccessChance(targetSystem: targetSystem), precisionSteps: 2);
    choices.add("Target ${targetSystem.name} [$probability]",
        script: () {
      this.targetSystem = targetSystem;
    });
  }
}

//class RedistributeEnergy extends CombatMove {
//  RedistributeEnergy() : super("<subject> redistribute<s> energy", 
//      timeToSetup: 1, timeToFinish: 1, needsTarget: false);
//  
//  
//}
