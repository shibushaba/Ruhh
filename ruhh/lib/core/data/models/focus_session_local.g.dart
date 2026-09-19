// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_session_local.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFocusSessionLocalCollection on Isar {
  IsarCollection<FocusSessionLocal> get focusSessionLocals => this.collection();
}

const FocusSessionLocalSchema = CollectionSchema(
  name: r'FocusSessionLocal',
  id: -3123625828663525883,
  properties: {
    r'completed': PropertySchema(
      id: 0,
      name: r'completed',
      type: IsarType.bool,
    ),
    r'habitRemoteId': PropertySchema(
      id: 1,
      name: r'habitRemoteId',
      type: IsarType.string,
    ),
    r'remoteId': PropertySchema(
      id: 2,
      name: r'remoteId',
      type: IsarType.string,
    ),
    r'seconds': PropertySchema(
      id: 3,
      name: r'seconds',
      type: IsarType.long,
    ),
    r'startedAt': PropertySchema(
      id: 4,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'targetMinutes': PropertySchema(
      id: 5,
      name: r'targetMinutes',
      type: IsarType.long,
    ),
    r'userId': PropertySchema(
      id: 6,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _focusSessionLocalEstimateSize,
  serialize: _focusSessionLocalSerialize,
  deserialize: _focusSessionLocalDeserialize,
  deserializeProp: _focusSessionLocalDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _focusSessionLocalGetId,
  getLinks: _focusSessionLocalGetLinks,
  attach: _focusSessionLocalAttach,
  version: '3.1.0+1',
);

int _focusSessionLocalEstimateSize(
  FocusSessionLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.habitRemoteId.length * 3;
  bytesCount += 3 + object.remoteId.length * 3;
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _focusSessionLocalSerialize(
  FocusSessionLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.completed);
  writer.writeString(offsets[1], object.habitRemoteId);
  writer.writeString(offsets[2], object.remoteId);
  writer.writeLong(offsets[3], object.seconds);
  writer.writeDateTime(offsets[4], object.startedAt);
  writer.writeLong(offsets[5], object.targetMinutes);
  writer.writeString(offsets[6], object.userId);
}

FocusSessionLocal _focusSessionLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FocusSessionLocal();
  object.completed = reader.readBool(offsets[0]);
  object.habitRemoteId = reader.readString(offsets[1]);
  object.id = id;
  object.remoteId = reader.readString(offsets[2]);
  object.seconds = reader.readLong(offsets[3]);
  object.startedAt = reader.readDateTime(offsets[4]);
  object.targetMinutes = reader.readLong(offsets[5]);
  object.userId = reader.readString(offsets[6]);
  return object;
}

P _focusSessionLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _focusSessionLocalGetId(FocusSessionLocal object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _focusSessionLocalGetLinks(
    FocusSessionLocal object) {
  return [];
}

void _focusSessionLocalAttach(
    IsarCollection<dynamic> col, Id id, FocusSessionLocal object) {
  object.id = id;
}

extension FocusSessionLocalQueryWhereSort
    on QueryBuilder<FocusSessionLocal, FocusSessionLocal, QWhere> {
  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FocusSessionLocalQueryWhere
    on QueryBuilder<FocusSessionLocal, FocusSessionLocal, QWhereClause> {
  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension FocusSessionLocalQueryFilter
    on QueryBuilder<FocusSessionLocal, FocusSessionLocal, QFilterCondition> {
  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      completedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completed',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      habitRemoteIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'habitRemoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      habitRemoteIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'habitRemoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      habitRemoteIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'habitRemoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      habitRemoteIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'habitRemoteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      habitRemoteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'habitRemoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      habitRemoteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'habitRemoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      habitRemoteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'habitRemoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      habitRemoteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'habitRemoteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      habitRemoteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'habitRemoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      habitRemoteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'habitRemoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      remoteIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      remoteIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      remoteIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      remoteIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remoteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      remoteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      remoteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      remoteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      remoteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remoteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      remoteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      remoteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      secondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seconds',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      secondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'seconds',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      secondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'seconds',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      secondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'seconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      startedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      startedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      startedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      startedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      targetMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      targetMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      targetMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      targetMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension FocusSessionLocalQueryObject
    on QueryBuilder<FocusSessionLocal, FocusSessionLocal, QFilterCondition> {}

extension FocusSessionLocalQueryLinks
    on QueryBuilder<FocusSessionLocal, FocusSessionLocal, QFilterCondition> {}

extension FocusSessionLocalQuerySortBy
    on QueryBuilder<FocusSessionLocal, FocusSessionLocal, QSortBy> {
  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      sortByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      sortByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      sortByHabitRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitRemoteId', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      sortByHabitRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitRemoteId', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      sortBySeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seconds', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      sortBySecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seconds', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      sortByTargetMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetMinutes', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      sortByTargetMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetMinutes', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension FocusSessionLocalQuerySortThenBy
    on QueryBuilder<FocusSessionLocal, FocusSessionLocal, QSortThenBy> {
  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenByHabitRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitRemoteId', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenByHabitRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitRemoteId', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenBySeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seconds', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenBySecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seconds', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenByTargetMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetMinutes', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenByTargetMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetMinutes', Sort.desc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension FocusSessionLocalQueryWhereDistinct
    on QueryBuilder<FocusSessionLocal, FocusSessionLocal, QDistinct> {
  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QDistinct>
      distinctByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completed');
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QDistinct>
      distinctByHabitRemoteId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'habitRemoteId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QDistinct>
      distinctByRemoteId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QDistinct>
      distinctBySeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seconds');
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QDistinct>
      distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QDistinct>
      distinctByTargetMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetMinutes');
    });
  }

  QueryBuilder<FocusSessionLocal, FocusSessionLocal, QDistinct>
      distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension FocusSessionLocalQueryProperty
    on QueryBuilder<FocusSessionLocal, FocusSessionLocal, QQueryProperty> {
  QueryBuilder<FocusSessionLocal, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FocusSessionLocal, bool, QQueryOperations> completedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completed');
    });
  }

  QueryBuilder<FocusSessionLocal, String, QQueryOperations>
      habitRemoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'habitRemoteId');
    });
  }

  QueryBuilder<FocusSessionLocal, String, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<FocusSessionLocal, int, QQueryOperations> secondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seconds');
    });
  }

  QueryBuilder<FocusSessionLocal, DateTime, QQueryOperations>
      startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<FocusSessionLocal, int, QQueryOperations>
      targetMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetMinutes');
    });
  }

  QueryBuilder<FocusSessionLocal, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
