// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CardsTable extends Cards with TableInfo<$CardsTable, Card> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldsMeta = const VerificationMeta('fields');
  @override
  late final GeneratedColumn<String> fields = GeneratedColumn<String>(
    'fields',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldSpeakableMeta = const VerificationMeta(
    'fieldSpeakable',
  );
  @override
  late final GeneratedColumn<String> fieldSpeakable = GeneratedColumn<String>(
    'field_speakable',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    language,
    fields,
    fieldSpeakable,
    tags,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Card> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('fields')) {
      context.handle(
        _fieldsMeta,
        fields.isAcceptableOrUnknown(data['fields']!, _fieldsMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldsMeta);
    }
    if (data.containsKey('field_speakable')) {
      context.handle(
        _fieldSpeakableMeta,
        fieldSpeakable.isAcceptableOrUnknown(
          data['field_speakable']!,
          _fieldSpeakableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fieldSpeakableMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Card map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Card(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      fields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fields'],
      )!,
      fieldSpeakable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_speakable'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class Card extends DataClass implements Insertable<Card> {
  final int id;
  final String language;
  final String fields;
  final String fieldSpeakable;
  final String tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Card({
    required this.id,
    required this.language,
    required this.fields,
    required this.fieldSpeakable,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['language'] = Variable<String>(language);
    map['fields'] = Variable<String>(fields);
    map['field_speakable'] = Variable<String>(fieldSpeakable);
    map['tags'] = Variable<String>(tags);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      language: Value(language),
      fields: Value(fields),
      fieldSpeakable: Value(fieldSpeakable),
      tags: Value(tags),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Card.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Card(
      id: serializer.fromJson<int>(json['id']),
      language: serializer.fromJson<String>(json['language']),
      fields: serializer.fromJson<String>(json['fields']),
      fieldSpeakable: serializer.fromJson<String>(json['fieldSpeakable']),
      tags: serializer.fromJson<String>(json['tags']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'language': serializer.toJson<String>(language),
      'fields': serializer.toJson<String>(fields),
      'fieldSpeakable': serializer.toJson<String>(fieldSpeakable),
      'tags': serializer.toJson<String>(tags),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Card copyWith({
    int? id,
    String? language,
    String? fields,
    String? fieldSpeakable,
    String? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Card(
    id: id ?? this.id,
    language: language ?? this.language,
    fields: fields ?? this.fields,
    fieldSpeakable: fieldSpeakable ?? this.fieldSpeakable,
    tags: tags ?? this.tags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Card copyWithCompanion(CardsCompanion data) {
    return Card(
      id: data.id.present ? data.id.value : this.id,
      language: data.language.present ? data.language.value : this.language,
      fields: data.fields.present ? data.fields.value : this.fields,
      fieldSpeakable: data.fieldSpeakable.present
          ? data.fieldSpeakable.value
          : this.fieldSpeakable,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Card(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('fields: $fields, ')
          ..write('fieldSpeakable: $fieldSpeakable, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    language,
    fields,
    fieldSpeakable,
    tags,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Card &&
          other.id == this.id &&
          other.language == this.language &&
          other.fields == this.fields &&
          other.fieldSpeakable == this.fieldSpeakable &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CardsCompanion extends UpdateCompanion<Card> {
  final Value<int> id;
  final Value<String> language;
  final Value<String> fields;
  final Value<String> fieldSpeakable;
  final Value<String> tags;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.language = const Value.absent(),
    this.fields = const Value.absent(),
    this.fieldSpeakable = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  CardsCompanion.insert({
    this.id = const Value.absent(),
    required String language,
    required String fields,
    required String fieldSpeakable,
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : language = Value(language),
       fields = Value(fields),
       fieldSpeakable = Value(fieldSpeakable);
  static Insertable<Card> custom({
    Expression<int>? id,
    Expression<String>? language,
    Expression<String>? fields,
    Expression<String>? fieldSpeakable,
    Expression<String>? tags,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (language != null) 'language': language,
      if (fields != null) 'fields': fields,
      if (fieldSpeakable != null) 'field_speakable': fieldSpeakable,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  CardsCompanion copyWith({
    Value<int>? id,
    Value<String>? language,
    Value<String>? fields,
    Value<String>? fieldSpeakable,
    Value<String>? tags,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return CardsCompanion(
      id: id ?? this.id,
      language: language ?? this.language,
      fields: fields ?? this.fields,
      fieldSpeakable: fieldSpeakable ?? this.fieldSpeakable,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (fields.present) {
      map['fields'] = Variable<String>(fields.value);
    }
    if (fieldSpeakable.present) {
      map['field_speakable'] = Variable<String>(fieldSpeakable.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('fields: $fields, ')
          ..write('fieldSpeakable: $fieldSpeakable, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $FsrsStatesTable extends FsrsStates
    with TableInfo<$FsrsStatesTable, FsrsState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FsrsStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cards (id)',
    ),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
    'step',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<DateTime> due = GeneratedColumn<DateTime>(
    'due',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewMeta = const VerificationMeta(
    'lastReview',
  );
  @override
  late final GeneratedColumn<DateTime> lastReview = GeneratedColumn<DateTime>(
    'last_review',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cardId,
    state,
    step,
    stability,
    difficulty,
    due,
    lastReview,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fsrs_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<FsrsState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    } else if (isInserting) {
      context.missing(_dueMeta);
    }
    if (data.containsKey('last_review')) {
      context.handle(
        _lastReviewMeta,
        lastReview.isAcceptableOrUnknown(data['last_review']!, _lastReviewMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cardId};
  @override
  FsrsState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FsrsState(
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state'],
      )!,
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step'],
      ),
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      ),
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due'],
      )!,
      lastReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review'],
      ),
    );
  }

  @override
  $FsrsStatesTable createAlias(String alias) {
    return $FsrsStatesTable(attachedDatabase, alias);
  }
}

class FsrsState extends DataClass implements Insertable<FsrsState> {
  final int cardId;
  final int state;
  final int? step;
  final double? stability;
  final double? difficulty;
  final DateTime due;
  final DateTime? lastReview;
  const FsrsState({
    required this.cardId,
    required this.state,
    this.step,
    this.stability,
    this.difficulty,
    required this.due,
    this.lastReview,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['card_id'] = Variable<int>(cardId);
    map['state'] = Variable<int>(state);
    if (!nullToAbsent || step != null) {
      map['step'] = Variable<int>(step);
    }
    if (!nullToAbsent || stability != null) {
      map['stability'] = Variable<double>(stability);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<double>(difficulty);
    }
    map['due'] = Variable<DateTime>(due);
    if (!nullToAbsent || lastReview != null) {
      map['last_review'] = Variable<DateTime>(lastReview);
    }
    return map;
  }

  FsrsStatesCompanion toCompanion(bool nullToAbsent) {
    return FsrsStatesCompanion(
      cardId: Value(cardId),
      state: Value(state),
      step: step == null && nullToAbsent ? const Value.absent() : Value(step),
      stability: stability == null && nullToAbsent
          ? const Value.absent()
          : Value(stability),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      due: Value(due),
      lastReview: lastReview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReview),
    );
  }

  factory FsrsState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FsrsState(
      cardId: serializer.fromJson<int>(json['cardId']),
      state: serializer.fromJson<int>(json['state']),
      step: serializer.fromJson<int?>(json['step']),
      stability: serializer.fromJson<double?>(json['stability']),
      difficulty: serializer.fromJson<double?>(json['difficulty']),
      due: serializer.fromJson<DateTime>(json['due']),
      lastReview: serializer.fromJson<DateTime?>(json['lastReview']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cardId': serializer.toJson<int>(cardId),
      'state': serializer.toJson<int>(state),
      'step': serializer.toJson<int?>(step),
      'stability': serializer.toJson<double?>(stability),
      'difficulty': serializer.toJson<double?>(difficulty),
      'due': serializer.toJson<DateTime>(due),
      'lastReview': serializer.toJson<DateTime?>(lastReview),
    };
  }

  FsrsState copyWith({
    int? cardId,
    int? state,
    Value<int?> step = const Value.absent(),
    Value<double?> stability = const Value.absent(),
    Value<double?> difficulty = const Value.absent(),
    DateTime? due,
    Value<DateTime?> lastReview = const Value.absent(),
  }) => FsrsState(
    cardId: cardId ?? this.cardId,
    state: state ?? this.state,
    step: step.present ? step.value : this.step,
    stability: stability.present ? stability.value : this.stability,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    due: due ?? this.due,
    lastReview: lastReview.present ? lastReview.value : this.lastReview,
  );
  FsrsState copyWithCompanion(FsrsStatesCompanion data) {
    return FsrsState(
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      state: data.state.present ? data.state.value : this.state,
      step: data.step.present ? data.step.value : this.step,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      due: data.due.present ? data.due.value : this.due,
      lastReview: data.lastReview.present
          ? data.lastReview.value
          : this.lastReview,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FsrsState(')
          ..write('cardId: $cardId, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(cardId, state, step, stability, difficulty, due, lastReview);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FsrsState &&
          other.cardId == this.cardId &&
          other.state == this.state &&
          other.step == this.step &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.due == this.due &&
          other.lastReview == this.lastReview);
}

class FsrsStatesCompanion extends UpdateCompanion<FsrsState> {
  final Value<int> cardId;
  final Value<int> state;
  final Value<int?> step;
  final Value<double?> stability;
  final Value<double?> difficulty;
  final Value<DateTime> due;
  final Value<DateTime?> lastReview;
  const FsrsStatesCompanion({
    this.cardId = const Value.absent(),
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.due = const Value.absent(),
    this.lastReview = const Value.absent(),
  });
  FsrsStatesCompanion.insert({
    this.cardId = const Value.absent(),
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    required DateTime due,
    this.lastReview = const Value.absent(),
  }) : due = Value(due);
  static Insertable<FsrsState> custom({
    Expression<int>? cardId,
    Expression<int>? state,
    Expression<int>? step,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<DateTime>? due,
    Expression<DateTime>? lastReview,
  }) {
    return RawValuesInsertable({
      if (cardId != null) 'card_id': cardId,
      if (state != null) 'state': state,
      if (step != null) 'step': step,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (due != null) 'due': due,
      if (lastReview != null) 'last_review': lastReview,
    });
  }

  FsrsStatesCompanion copyWith({
    Value<int>? cardId,
    Value<int>? state,
    Value<int?>? step,
    Value<double?>? stability,
    Value<double?>? difficulty,
    Value<DateTime>? due,
    Value<DateTime?>? lastReview,
  }) {
    return FsrsStatesCompanion(
      cardId: cardId ?? this.cardId,
      state: state ?? this.state,
      step: step ?? this.step,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      due: due ?? this.due,
      lastReview: lastReview ?? this.lastReview,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (due.present) {
      map['due'] = Variable<DateTime>(due.value);
    }
    if (lastReview.present) {
      map['last_review'] = Variable<DateTime>(lastReview.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FsrsStatesCompanion(')
          ..write('cardId: $cardId, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview')
          ..write(')'))
        .toString();
  }
}

class $ReviewEventsTable extends ReviewEvents
    with TableInfo<$ReviewEventsTable, ReviewEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cards (id)',
    ),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studyModeMeta = const VerificationMeta(
    'studyMode',
  );
  @override
  late final GeneratedColumn<String> studyMode = GeneratedColumn<String>(
    'study_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('reading'),
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('source_to_target'),
  );
  static const VerificationMeta _audioReplayCountMeta = const VerificationMeta(
    'audioReplayCount',
  );
  @override
  late final GeneratedColumn<int> audioReplayCount = GeneratedColumn<int>(
    'audio_replay_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _playbackSpeedMeta = const VerificationMeta(
    'playbackSpeed',
  );
  @override
  late final GeneratedColumn<double> playbackSpeed = GeneratedColumn<double>(
    'playback_speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _timeToRevealSecondsMeta =
      const VerificationMeta('timeToRevealSeconds');
  @override
  late final GeneratedColumn<double> timeToRevealSeconds =
      GeneratedColumn<double>(
        'time_to_reveal_seconds',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    rating,
    studyMode,
    direction,
    audioReplayCount,
    playbackSpeed,
    timeToRevealSeconds,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('study_mode')) {
      context.handle(
        _studyModeMeta,
        studyMode.isAcceptableOrUnknown(data['study_mode']!, _studyModeMeta),
      );
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    }
    if (data.containsKey('audio_replay_count')) {
      context.handle(
        _audioReplayCountMeta,
        audioReplayCount.isAcceptableOrUnknown(
          data['audio_replay_count']!,
          _audioReplayCountMeta,
        ),
      );
    }
    if (data.containsKey('playback_speed')) {
      context.handle(
        _playbackSpeedMeta,
        playbackSpeed.isAcceptableOrUnknown(
          data['playback_speed']!,
          _playbackSpeedMeta,
        ),
      );
    }
    if (data.containsKey('time_to_reveal_seconds')) {
      context.handle(
        _timeToRevealSecondsMeta,
        timeToRevealSeconds.isAcceptableOrUnknown(
          data['time_to_reveal_seconds']!,
          _timeToRevealSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeToRevealSecondsMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      studyMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}study_mode'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      audioReplayCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}audio_replay_count'],
      )!,
      playbackSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}playback_speed'],
      )!,
      timeToRevealSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}time_to_reveal_seconds'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $ReviewEventsTable createAlias(String alias) {
    return $ReviewEventsTable(attachedDatabase, alias);
  }
}

class ReviewEvent extends DataClass implements Insertable<ReviewEvent> {
  final int id;
  final int cardId;
  final int rating;
  final String studyMode;
  final String direction;
  final int audioReplayCount;
  final double playbackSpeed;
  final double timeToRevealSeconds;
  final DateTime timestamp;
  const ReviewEvent({
    required this.id,
    required this.cardId,
    required this.rating,
    required this.studyMode,
    required this.direction,
    required this.audioReplayCount,
    required this.playbackSpeed,
    required this.timeToRevealSeconds,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<int>(cardId);
    map['rating'] = Variable<int>(rating);
    map['study_mode'] = Variable<String>(studyMode);
    map['direction'] = Variable<String>(direction);
    map['audio_replay_count'] = Variable<int>(audioReplayCount);
    map['playback_speed'] = Variable<double>(playbackSpeed);
    map['time_to_reveal_seconds'] = Variable<double>(timeToRevealSeconds);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  ReviewEventsCompanion toCompanion(bool nullToAbsent) {
    return ReviewEventsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      rating: Value(rating),
      studyMode: Value(studyMode),
      direction: Value(direction),
      audioReplayCount: Value(audioReplayCount),
      playbackSpeed: Value(playbackSpeed),
      timeToRevealSeconds: Value(timeToRevealSeconds),
      timestamp: Value(timestamp),
    );
  }

  factory ReviewEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewEvent(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<int>(json['cardId']),
      rating: serializer.fromJson<int>(json['rating']),
      studyMode: serializer.fromJson<String>(json['studyMode']),
      direction: serializer.fromJson<String>(json['direction']),
      audioReplayCount: serializer.fromJson<int>(json['audioReplayCount']),
      playbackSpeed: serializer.fromJson<double>(json['playbackSpeed']),
      timeToRevealSeconds: serializer.fromJson<double>(
        json['timeToRevealSeconds'],
      ),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<int>(cardId),
      'rating': serializer.toJson<int>(rating),
      'studyMode': serializer.toJson<String>(studyMode),
      'direction': serializer.toJson<String>(direction),
      'audioReplayCount': serializer.toJson<int>(audioReplayCount),
      'playbackSpeed': serializer.toJson<double>(playbackSpeed),
      'timeToRevealSeconds': serializer.toJson<double>(timeToRevealSeconds),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  ReviewEvent copyWith({
    int? id,
    int? cardId,
    int? rating,
    String? studyMode,
    String? direction,
    int? audioReplayCount,
    double? playbackSpeed,
    double? timeToRevealSeconds,
    DateTime? timestamp,
  }) => ReviewEvent(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    rating: rating ?? this.rating,
    studyMode: studyMode ?? this.studyMode,
    direction: direction ?? this.direction,
    audioReplayCount: audioReplayCount ?? this.audioReplayCount,
    playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    timeToRevealSeconds: timeToRevealSeconds ?? this.timeToRevealSeconds,
    timestamp: timestamp ?? this.timestamp,
  );
  ReviewEvent copyWithCompanion(ReviewEventsCompanion data) {
    return ReviewEvent(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      rating: data.rating.present ? data.rating.value : this.rating,
      studyMode: data.studyMode.present ? data.studyMode.value : this.studyMode,
      direction: data.direction.present ? data.direction.value : this.direction,
      audioReplayCount: data.audioReplayCount.present
          ? data.audioReplayCount.value
          : this.audioReplayCount,
      playbackSpeed: data.playbackSpeed.present
          ? data.playbackSpeed.value
          : this.playbackSpeed,
      timeToRevealSeconds: data.timeToRevealSeconds.present
          ? data.timeToRevealSeconds.value
          : this.timeToRevealSeconds,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEvent(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('rating: $rating, ')
          ..write('studyMode: $studyMode, ')
          ..write('direction: $direction, ')
          ..write('audioReplayCount: $audioReplayCount, ')
          ..write('playbackSpeed: $playbackSpeed, ')
          ..write('timeToRevealSeconds: $timeToRevealSeconds, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardId,
    rating,
    studyMode,
    direction,
    audioReplayCount,
    playbackSpeed,
    timeToRevealSeconds,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewEvent &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.rating == this.rating &&
          other.studyMode == this.studyMode &&
          other.direction == this.direction &&
          other.audioReplayCount == this.audioReplayCount &&
          other.playbackSpeed == this.playbackSpeed &&
          other.timeToRevealSeconds == this.timeToRevealSeconds &&
          other.timestamp == this.timestamp);
}

class ReviewEventsCompanion extends UpdateCompanion<ReviewEvent> {
  final Value<int> id;
  final Value<int> cardId;
  final Value<int> rating;
  final Value<String> studyMode;
  final Value<String> direction;
  final Value<int> audioReplayCount;
  final Value<double> playbackSpeed;
  final Value<double> timeToRevealSeconds;
  final Value<DateTime> timestamp;
  const ReviewEventsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.rating = const Value.absent(),
    this.studyMode = const Value.absent(),
    this.direction = const Value.absent(),
    this.audioReplayCount = const Value.absent(),
    this.playbackSpeed = const Value.absent(),
    this.timeToRevealSeconds = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  ReviewEventsCompanion.insert({
    this.id = const Value.absent(),
    required int cardId,
    required int rating,
    this.studyMode = const Value.absent(),
    this.direction = const Value.absent(),
    this.audioReplayCount = const Value.absent(),
    this.playbackSpeed = const Value.absent(),
    required double timeToRevealSeconds,
    this.timestamp = const Value.absent(),
  }) : cardId = Value(cardId),
       rating = Value(rating),
       timeToRevealSeconds = Value(timeToRevealSeconds);
  static Insertable<ReviewEvent> custom({
    Expression<int>? id,
    Expression<int>? cardId,
    Expression<int>? rating,
    Expression<String>? studyMode,
    Expression<String>? direction,
    Expression<int>? audioReplayCount,
    Expression<double>? playbackSpeed,
    Expression<double>? timeToRevealSeconds,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (rating != null) 'rating': rating,
      if (studyMode != null) 'study_mode': studyMode,
      if (direction != null) 'direction': direction,
      if (audioReplayCount != null) 'audio_replay_count': audioReplayCount,
      if (playbackSpeed != null) 'playback_speed': playbackSpeed,
      if (timeToRevealSeconds != null)
        'time_to_reveal_seconds': timeToRevealSeconds,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  ReviewEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? cardId,
    Value<int>? rating,
    Value<String>? studyMode,
    Value<String>? direction,
    Value<int>? audioReplayCount,
    Value<double>? playbackSpeed,
    Value<double>? timeToRevealSeconds,
    Value<DateTime>? timestamp,
  }) {
    return ReviewEventsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      rating: rating ?? this.rating,
      studyMode: studyMode ?? this.studyMode,
      direction: direction ?? this.direction,
      audioReplayCount: audioReplayCount ?? this.audioReplayCount,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      timeToRevealSeconds: timeToRevealSeconds ?? this.timeToRevealSeconds,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (studyMode.present) {
      map['study_mode'] = Variable<String>(studyMode.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (audioReplayCount.present) {
      map['audio_replay_count'] = Variable<int>(audioReplayCount.value);
    }
    if (playbackSpeed.present) {
      map['playback_speed'] = Variable<double>(playbackSpeed.value);
    }
    if (timeToRevealSeconds.present) {
      map['time_to_reveal_seconds'] = Variable<double>(
        timeToRevealSeconds.value,
      );
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEventsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('rating: $rating, ')
          ..write('studyMode: $studyMode, ')
          ..write('direction: $direction, ')
          ..write('audioReplayCount: $audioReplayCount, ')
          ..write('playbackSpeed: $playbackSpeed, ')
          ..write('timeToRevealSeconds: $timeToRevealSeconds, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

abstract class _$RecallDatabase extends GeneratedDatabase {
  _$RecallDatabase(QueryExecutor e) : super(e);
  $RecallDatabaseManager get managers => $RecallDatabaseManager(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $FsrsStatesTable fsrsStates = $FsrsStatesTable(this);
  late final $ReviewEventsTable reviewEvents = $ReviewEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cards,
    fsrsStates,
    reviewEvents,
  ];
}

typedef $$CardsTableCreateCompanionBuilder =
    CardsCompanion Function({
      Value<int> id,
      required String language,
      required String fields,
      required String fieldSpeakable,
      Value<String> tags,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$CardsTableUpdateCompanionBuilder =
    CardsCompanion Function({
      Value<int> id,
      Value<String> language,
      Value<String> fields,
      Value<String> fieldSpeakable,
      Value<String> tags,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });

final class $$CardsTableReferences
    extends BaseReferences<_$RecallDatabase, $CardsTable, Card> {
  $$CardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FsrsStatesTable, List<FsrsState>>
  _fsrsStatesRefsTable(_$RecallDatabase db) => MultiTypedResultKey.fromTable(
    db.fsrsStates,
    aliasName: $_aliasNameGenerator(db.cards.id, db.fsrsStates.cardId),
  );

  $$FsrsStatesTableProcessedTableManager get fsrsStatesRefs {
    final manager = $$FsrsStatesTableTableManager(
      $_db,
      $_db.fsrsStates,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_fsrsStatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReviewEventsTable, List<ReviewEvent>>
  _reviewEventsRefsTable(_$RecallDatabase db) => MultiTypedResultKey.fromTable(
    db.reviewEvents,
    aliasName: $_aliasNameGenerator(db.cards.id, db.reviewEvents.cardId),
  );

  $$ReviewEventsTableProcessedTableManager get reviewEventsRefs {
    final manager = $$ReviewEventsTableTableManager(
      $_db,
      $_db.reviewEvents,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CardsTableFilterComposer
    extends Composer<_$RecallDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fields => $composableBuilder(
    column: $table.fields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldSpeakable => $composableBuilder(
    column: $table.fieldSpeakable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> fsrsStatesRefs(
    Expression<bool> Function($$FsrsStatesTableFilterComposer f) f,
  ) {
    final $$FsrsStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fsrsStates,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FsrsStatesTableFilterComposer(
            $db: $db,
            $table: $db.fsrsStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reviewEventsRefs(
    Expression<bool> Function($$ReviewEventsTableFilterComposer f) f,
  ) {
    final $$ReviewEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewEvents,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewEventsTableFilterComposer(
            $db: $db,
            $table: $db.reviewEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CardsTableOrderingComposer
    extends Composer<_$RecallDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fields => $composableBuilder(
    column: $table.fields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldSpeakable => $composableBuilder(
    column: $table.fieldSpeakable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CardsTableAnnotationComposer
    extends Composer<_$RecallDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get fields =>
      $composableBuilder(column: $table.fields, builder: (column) => column);

  GeneratedColumn<String> get fieldSpeakable => $composableBuilder(
    column: $table.fieldSpeakable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> fsrsStatesRefs<T extends Object>(
    Expression<T> Function($$FsrsStatesTableAnnotationComposer a) f,
  ) {
    final $$FsrsStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fsrsStates,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FsrsStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.fsrsStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reviewEventsRefs<T extends Object>(
    Expression<T> Function($$ReviewEventsTableAnnotationComposer a) f,
  ) {
    final $$ReviewEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewEvents,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CardsTableTableManager
    extends
        RootTableManager<
          _$RecallDatabase,
          $CardsTable,
          Card,
          $$CardsTableFilterComposer,
          $$CardsTableOrderingComposer,
          $$CardsTableAnnotationComposer,
          $$CardsTableCreateCompanionBuilder,
          $$CardsTableUpdateCompanionBuilder,
          (Card, $$CardsTableReferences),
          Card,
          PrefetchHooks Function({bool fsrsStatesRefs, bool reviewEventsRefs})
        > {
  $$CardsTableTableManager(_$RecallDatabase db, $CardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> fields = const Value.absent(),
                Value<String> fieldSpeakable = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => CardsCompanion(
                id: id,
                language: language,
                fields: fields,
                fieldSpeakable: fieldSpeakable,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String language,
                required String fields,
                required String fieldSpeakable,
                Value<String> tags = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => CardsCompanion.insert(
                id: id,
                language: language,
                fields: fields,
                fieldSpeakable: fieldSpeakable,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CardsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({fsrsStatesRefs = false, reviewEventsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (fsrsStatesRefs) db.fsrsStates,
                    if (reviewEventsRefs) db.reviewEvents,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (fsrsStatesRefs)
                        await $_getPrefetchedData<Card, $CardsTable, FsrsState>(
                          currentTable: table,
                          referencedTable: $$CardsTableReferences
                              ._fsrsStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CardsTableReferences(
                                db,
                                table,
                                p0,
                              ).fsrsStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cardId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reviewEventsRefs)
                        await $_getPrefetchedData<
                          Card,
                          $CardsTable,
                          ReviewEvent
                        >(
                          currentTable: table,
                          referencedTable: $$CardsTableReferences
                              ._reviewEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CardsTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cardId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CardsTableProcessedTableManager =
    ProcessedTableManager<
      _$RecallDatabase,
      $CardsTable,
      Card,
      $$CardsTableFilterComposer,
      $$CardsTableOrderingComposer,
      $$CardsTableAnnotationComposer,
      $$CardsTableCreateCompanionBuilder,
      $$CardsTableUpdateCompanionBuilder,
      (Card, $$CardsTableReferences),
      Card,
      PrefetchHooks Function({bool fsrsStatesRefs, bool reviewEventsRefs})
    >;
typedef $$FsrsStatesTableCreateCompanionBuilder =
    FsrsStatesCompanion Function({
      Value<int> cardId,
      Value<int> state,
      Value<int?> step,
      Value<double?> stability,
      Value<double?> difficulty,
      required DateTime due,
      Value<DateTime?> lastReview,
    });
typedef $$FsrsStatesTableUpdateCompanionBuilder =
    FsrsStatesCompanion Function({
      Value<int> cardId,
      Value<int> state,
      Value<int?> step,
      Value<double?> stability,
      Value<double?> difficulty,
      Value<DateTime> due,
      Value<DateTime?> lastReview,
    });

final class $$FsrsStatesTableReferences
    extends BaseReferences<_$RecallDatabase, $FsrsStatesTable, FsrsState> {
  $$FsrsStatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CardsTable _cardIdTable(_$RecallDatabase db) => db.cards.createAlias(
    $_aliasNameGenerator(db.fsrsStates.cardId, db.cards.id),
  );

  $$CardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<int>('card_id')!;

    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FsrsStatesTableFilterComposer
    extends Composer<_$RecallDatabase, $FsrsStatesTable> {
  $$FsrsStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnFilters(column),
  );

  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FsrsStatesTableOrderingComposer
    extends Composer<_$RecallDatabase, $FsrsStatesTable> {
  $$FsrsStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnOrderings(column),
  );

  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableOrderingComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FsrsStatesTableAnnotationComposer
    extends Composer<_$RecallDatabase, $FsrsStatesTable> {
  $$FsrsStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => column,
  );

  $$CardsTableAnnotationComposer get cardId {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FsrsStatesTableTableManager
    extends
        RootTableManager<
          _$RecallDatabase,
          $FsrsStatesTable,
          FsrsState,
          $$FsrsStatesTableFilterComposer,
          $$FsrsStatesTableOrderingComposer,
          $$FsrsStatesTableAnnotationComposer,
          $$FsrsStatesTableCreateCompanionBuilder,
          $$FsrsStatesTableUpdateCompanionBuilder,
          (FsrsState, $$FsrsStatesTableReferences),
          FsrsState,
          PrefetchHooks Function({bool cardId})
        > {
  $$FsrsStatesTableTableManager(_$RecallDatabase db, $FsrsStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FsrsStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FsrsStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FsrsStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> cardId = const Value.absent(),
                Value<int> state = const Value.absent(),
                Value<int?> step = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                Value<DateTime> due = const Value.absent(),
                Value<DateTime?> lastReview = const Value.absent(),
              }) => FsrsStatesCompanion(
                cardId: cardId,
                state: state,
                step: step,
                stability: stability,
                difficulty: difficulty,
                due: due,
                lastReview: lastReview,
              ),
          createCompanionCallback:
              ({
                Value<int> cardId = const Value.absent(),
                Value<int> state = const Value.absent(),
                Value<int?> step = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                required DateTime due,
                Value<DateTime?> lastReview = const Value.absent(),
              }) => FsrsStatesCompanion.insert(
                cardId: cardId,
                state: state,
                step: step,
                stability: stability,
                difficulty: difficulty,
                due: due,
                lastReview: lastReview,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FsrsStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cardId,
                                referencedTable: $$FsrsStatesTableReferences
                                    ._cardIdTable(db),
                                referencedColumn: $$FsrsStatesTableReferences
                                    ._cardIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FsrsStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$RecallDatabase,
      $FsrsStatesTable,
      FsrsState,
      $$FsrsStatesTableFilterComposer,
      $$FsrsStatesTableOrderingComposer,
      $$FsrsStatesTableAnnotationComposer,
      $$FsrsStatesTableCreateCompanionBuilder,
      $$FsrsStatesTableUpdateCompanionBuilder,
      (FsrsState, $$FsrsStatesTableReferences),
      FsrsState,
      PrefetchHooks Function({bool cardId})
    >;
typedef $$ReviewEventsTableCreateCompanionBuilder =
    ReviewEventsCompanion Function({
      Value<int> id,
      required int cardId,
      required int rating,
      Value<String> studyMode,
      Value<String> direction,
      Value<int> audioReplayCount,
      Value<double> playbackSpeed,
      required double timeToRevealSeconds,
      Value<DateTime> timestamp,
    });
typedef $$ReviewEventsTableUpdateCompanionBuilder =
    ReviewEventsCompanion Function({
      Value<int> id,
      Value<int> cardId,
      Value<int> rating,
      Value<String> studyMode,
      Value<String> direction,
      Value<int> audioReplayCount,
      Value<double> playbackSpeed,
      Value<double> timeToRevealSeconds,
      Value<DateTime> timestamp,
    });

final class $$ReviewEventsTableReferences
    extends BaseReferences<_$RecallDatabase, $ReviewEventsTable, ReviewEvent> {
  $$ReviewEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CardsTable _cardIdTable(_$RecallDatabase db) => db.cards.createAlias(
    $_aliasNameGenerator(db.reviewEvents.cardId, db.cards.id),
  );

  $$CardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<int>('card_id')!;

    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewEventsTableFilterComposer
    extends Composer<_$RecallDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studyMode => $composableBuilder(
    column: $table.studyMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get audioReplayCount => $composableBuilder(
    column: $table.audioReplayCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get playbackSpeed => $composableBuilder(
    column: $table.playbackSpeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get timeToRevealSeconds => $composableBuilder(
    column: $table.timeToRevealSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewEventsTableOrderingComposer
    extends Composer<_$RecallDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studyMode => $composableBuilder(
    column: $table.studyMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get audioReplayCount => $composableBuilder(
    column: $table.audioReplayCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get playbackSpeed => $composableBuilder(
    column: $table.playbackSpeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get timeToRevealSeconds => $composableBuilder(
    column: $table.timeToRevealSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableOrderingComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewEventsTableAnnotationComposer
    extends Composer<_$RecallDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get studyMode =>
      $composableBuilder(column: $table.studyMode, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get audioReplayCount => $composableBuilder(
    column: $table.audioReplayCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get playbackSpeed => $composableBuilder(
    column: $table.playbackSpeed,
    builder: (column) => column,
  );

  GeneratedColumn<double> get timeToRevealSeconds => $composableBuilder(
    column: $table.timeToRevealSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$CardsTableAnnotationComposer get cardId {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewEventsTableTableManager
    extends
        RootTableManager<
          _$RecallDatabase,
          $ReviewEventsTable,
          ReviewEvent,
          $$ReviewEventsTableFilterComposer,
          $$ReviewEventsTableOrderingComposer,
          $$ReviewEventsTableAnnotationComposer,
          $$ReviewEventsTableCreateCompanionBuilder,
          $$ReviewEventsTableUpdateCompanionBuilder,
          (ReviewEvent, $$ReviewEventsTableReferences),
          ReviewEvent,
          PrefetchHooks Function({bool cardId})
        > {
  $$ReviewEventsTableTableManager(_$RecallDatabase db, $ReviewEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cardId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<String> studyMode = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<int> audioReplayCount = const Value.absent(),
                Value<double> playbackSpeed = const Value.absent(),
                Value<double> timeToRevealSeconds = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => ReviewEventsCompanion(
                id: id,
                cardId: cardId,
                rating: rating,
                studyMode: studyMode,
                direction: direction,
                audioReplayCount: audioReplayCount,
                playbackSpeed: playbackSpeed,
                timeToRevealSeconds: timeToRevealSeconds,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cardId,
                required int rating,
                Value<String> studyMode = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<int> audioReplayCount = const Value.absent(),
                Value<double> playbackSpeed = const Value.absent(),
                required double timeToRevealSeconds,
                Value<DateTime> timestamp = const Value.absent(),
              }) => ReviewEventsCompanion.insert(
                id: id,
                cardId: cardId,
                rating: rating,
                studyMode: studyMode,
                direction: direction,
                audioReplayCount: audioReplayCount,
                playbackSpeed: playbackSpeed,
                timeToRevealSeconds: timeToRevealSeconds,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReviewEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cardId,
                                referencedTable: $$ReviewEventsTableReferences
                                    ._cardIdTable(db),
                                referencedColumn: $$ReviewEventsTableReferences
                                    ._cardIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$RecallDatabase,
      $ReviewEventsTable,
      ReviewEvent,
      $$ReviewEventsTableFilterComposer,
      $$ReviewEventsTableOrderingComposer,
      $$ReviewEventsTableAnnotationComposer,
      $$ReviewEventsTableCreateCompanionBuilder,
      $$ReviewEventsTableUpdateCompanionBuilder,
      (ReviewEvent, $$ReviewEventsTableReferences),
      ReviewEvent,
      PrefetchHooks Function({bool cardId})
    >;

class $RecallDatabaseManager {
  final _$RecallDatabase _db;
  $RecallDatabaseManager(this._db);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$FsrsStatesTableTableManager get fsrsStates =>
      $$FsrsStatesTableTableManager(_db, _db.fsrsStates);
  $$ReviewEventsTableTableManager get reviewEvents =>
      $$ReviewEventsTableTableManager(_db, _db.reviewEvents);
}
