// GENERATED CODE - DO NOT MODIFY BY HAND

part of fractal_stories.items.weapon;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<DamageCapability> _$damageCapabilitySerializer =
    new _$DamageCapabilitySerializer();

class _$DamageCapabilitySerializer
    implements StructuredSerializer<DamageCapability> {
  @override
  final Iterable<Type> types = const [DamageCapability, _$DamageCapability];
  @override
  final String wireName = 'DamageCapability';

  @override
  Iterable<Object> serialize(Serializers serializers, DamageCapability object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'bluntDamage',
      serializers.serialize(object.bluntDamage,
          specifiedType: const FullType(int)),
      'isCleaving',
      serializers.serialize(object.isCleaving,
          specifiedType: const FullType(bool)),
      'length',
      serializers.serialize(object.length, specifiedType: const FullType(int)),
      'slashingDamage',
      serializers.serialize(object.slashingDamage,
          specifiedType: const FullType(int)),
      'tearingDamage',
      serializers.serialize(object.tearingDamage,
          specifiedType: const FullType(int)),
      'thrustingDamage',
      serializers.serialize(object.thrustingDamage,
          specifiedType: const FullType(int)),
      'type',
      serializers.serialize(object.type,
          specifiedType: const FullType(WeaponType)),
    ];

    return result;
  }

  @override
  DamageCapability deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new DamageCapabilityBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'bluntDamage':
          result.bluntDamage = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'isCleaving':
          result.isCleaving = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'length':
          result.length = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'slashingDamage':
          result.slashingDamage = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'tearingDamage':
          result.tearingDamage = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'thrustingDamage':
          result.thrustingDamage = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'type':
          result.type = serializers.deserialize(value,
              specifiedType: const FullType(WeaponType)) as WeaponType;
          break;
      }
    }

    return result.build();
  }
}

class _$DamageCapability extends DamageCapability {
  @override
  final int bluntDamage;
  @override
  final bool isCleaving;
  @override
  final int length;
  @override
  final int slashingDamage;
  @override
  final int tearingDamage;
  @override
  final int thrustingDamage;
  @override
  final WeaponType type;

  factory _$DamageCapability(
          [void Function(DamageCapabilityBuilder) updates]) =>
      (new DamageCapabilityBuilder()..update(updates)).build();

  _$DamageCapability._(
      {this.bluntDamage,
      this.isCleaving,
      this.length,
      this.slashingDamage,
      this.tearingDamage,
      this.thrustingDamage,
      this.type})
      : super._() {
    if (bluntDamage == null) {
      throw new BuiltValueNullFieldError('DamageCapability', 'bluntDamage');
    }
    if (isCleaving == null) {
      throw new BuiltValueNullFieldError('DamageCapability', 'isCleaving');
    }
    if (length == null) {
      throw new BuiltValueNullFieldError('DamageCapability', 'length');
    }
    if (slashingDamage == null) {
      throw new BuiltValueNullFieldError('DamageCapability', 'slashingDamage');
    }
    if (tearingDamage == null) {
      throw new BuiltValueNullFieldError('DamageCapability', 'tearingDamage');
    }
    if (thrustingDamage == null) {
      throw new BuiltValueNullFieldError('DamageCapability', 'thrustingDamage');
    }
    if (type == null) {
      throw new BuiltValueNullFieldError('DamageCapability', 'type');
    }
  }

  @override
  DamageCapability rebuild(void Function(DamageCapabilityBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DamageCapabilityBuilder toBuilder() =>
      new DamageCapabilityBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DamageCapability &&
        bluntDamage == other.bluntDamage &&
        isCleaving == other.isCleaving &&
        length == other.length &&
        slashingDamage == other.slashingDamage &&
        tearingDamage == other.tearingDamage &&
        thrustingDamage == other.thrustingDamage &&
        type == other.type;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc($jc($jc(0, bluntDamage.hashCode), isCleaving.hashCode),
                        length.hashCode),
                    slashingDamage.hashCode),
                tearingDamage.hashCode),
            thrustingDamage.hashCode),
        type.hashCode));
  }
}

class DamageCapabilityBuilder
    implements Builder<DamageCapability, DamageCapabilityBuilder> {
  _$DamageCapability _$v;

  int _bluntDamage;
  int get bluntDamage => _$this._bluntDamage;
  set bluntDamage(int bluntDamage) => _$this._bluntDamage = bluntDamage;

  bool _isCleaving;
  bool get isCleaving => _$this._isCleaving;
  set isCleaving(bool isCleaving) => _$this._isCleaving = isCleaving;

  int _length;
  int get length => _$this._length;
  set length(int length) => _$this._length = length;

  int _slashingDamage;
  int get slashingDamage => _$this._slashingDamage;
  set slashingDamage(int slashingDamage) =>
      _$this._slashingDamage = slashingDamage;

  int _tearingDamage;
  int get tearingDamage => _$this._tearingDamage;
  set tearingDamage(int tearingDamage) => _$this._tearingDamage = tearingDamage;

  int _thrustingDamage;
  int get thrustingDamage => _$this._thrustingDamage;
  set thrustingDamage(int thrustingDamage) =>
      _$this._thrustingDamage = thrustingDamage;

  WeaponType _type;
  WeaponType get type => _$this._type;
  set type(WeaponType type) => _$this._type = type;

  DamageCapabilityBuilder();

  DamageCapabilityBuilder get _$this {
    if (_$v != null) {
      _bluntDamage = _$v.bluntDamage;
      _isCleaving = _$v.isCleaving;
      _length = _$v.length;
      _slashingDamage = _$v.slashingDamage;
      _tearingDamage = _$v.tearingDamage;
      _thrustingDamage = _$v.thrustingDamage;
      _type = _$v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DamageCapability other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$DamageCapability;
  }

  @override
  void update(void Function(DamageCapabilityBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$DamageCapability build() {
    final _$result = _$v ??
        new _$DamageCapability._(
            bluntDamage: bluntDamage,
            isCleaving: isCleaving,
            length: length,
            slashingDamage: slashingDamage,
            tearingDamage: tearingDamage,
            thrustingDamage: thrustingDamage,
            type: type);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
