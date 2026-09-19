// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_local.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPrayerLogLocalCollection on Isar {
  IsarCollection<PrayerLogLocal> get prayerLogLocals => this.collection();
}

const PrayerLogLocalSchema = CollectionSchema(
  name: r'PrayerLogLocal',
  id: 3436135491646785938,
  properties: {
    r'day': PropertySchema(
      id: 0,
      name: r'day',
      type: IsarType.dateTime,
    ),
    r'prayer': PropertySchema(
      id: 1,
      name: r'prayer',
      type: IsarType.string,
      enumMap: _PrayerLogLocalprayerEnumValueMap,
    ),
    r'remoteId': PropertySchema(
      id: 2,
      name: r'remoteId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 3,
      name: r'status',
      type: IsarType.string,
      enumMap: _PrayerLogLocalstatusEnumValueMap,
    ),
    r'userId': PropertySchema(
      id: 4,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _prayerLogLocalEstimateSize,
  serialize: _prayerLogLocalSerialize,
  deserialize: _prayerLogLocalDeserialize,
  deserializeProp: _prayerLogLocalDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _prayerLogLocalGetId,
  getLinks: _prayerLogLocalGetLinks,
  attach: _prayerLogLocalAttach,
  version: '3.1.0+1',
);

int _prayerLogLocalEstimateSize(
  PrayerLogLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.prayer.name.length * 3;
  bytesCount += 3 + object.remoteId.length * 3;
  bytesCount += 3 + object.status.name.length * 3;
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _prayerLogLocalSerialize(
  PrayerLogLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.day);
  writer.writeString(offsets[1], object.prayer.name);
  writer.writeString(offsets[2], object.remoteId);
  writer.writeString(offsets[3], object.status.name);
  writer.writeString(offsets[4], object.userId);
}

PrayerLogLocal _prayerLogLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PrayerLogLocal();
  object.day = reader.readDateTime(offsets[0]);
  object.id = id;
  object.prayer =
      _PrayerLogLocalprayerValueEnumMap[reader.readStringOrNull(offsets[1])] ??
          PrayerName.fajr;
  object.remoteId = reader.readString(offsets[2]);
  object.status =
      _PrayerLogLocalstatusValueEnumMap[reader.readStringOrNull(offsets[3])] ??
          PrayerStatus.none;
  object.userId = reader.readString(offsets[4]);
  return object;
}

P _prayerLogLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (_PrayerLogLocalprayerValueEnumMap[
              reader.readStringOrNull(offset)] ??
          PrayerName.fajr) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (_PrayerLogLocalstatusValueEnumMap[
              reader.readStringOrNull(offset)] ??
          PrayerStatus.none) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PrayerLogLocalprayerEnumValueMap = {
  r'fajr': r'fajr',
  r'dhuhr': r'dhuhr',
  r'asr': r'asr',
  r'maghrib': r'maghrib',
  r'isha': r'isha',
};
const _PrayerLogLocalprayerValueEnumMap = {
  r'fajr': PrayerName.fajr,
  r'dhuhr': PrayerName.dhuhr,
  r'asr': PrayerName.asr,
  r'maghrib': PrayerName.maghrib,
  r'isha': PrayerName.isha,
};
const _PrayerLogLocalstatusEnumValueMap = {
  r'none': r'none',
  r'missed': r'missed',
  r'lateAlone': r'lateAlone',
  r'withGroup': r'withGroup',
  r'onTimeAlone': r'onTimeAlone',
  r'qadha': r'qadha',
};
const _PrayerLogLocalstatusValueEnumMap = {
  r'none': PrayerStatus.none,
  r'missed': PrayerStatus.missed,
  r'lateAlone': PrayerStatus.lateAlone,
  r'withGroup': PrayerStatus.withGroup,
  r'onTimeAlone': PrayerStatus.onTimeAlone,
  r'qadha': PrayerStatus.qadha,
};

Id _prayerLogLocalGetId(PrayerLogLocal object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _prayerLogLocalGetLinks(PrayerLogLocal object) {
  return [];
}

void _prayerLogLocalAttach(
    IsarCollection<dynamic> col, Id id, PrayerLogLocal object) {
  object.id = id;
}

extension PrayerLogLocalQueryWhereSort
    on QueryBuilder<PrayerLogLocal, PrayerLogLocal, QWhere> {
  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PrayerLogLocalQueryWhere
    on QueryBuilder<PrayerLogLocal, PrayerLogLocal, QWhereClause> {
  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterWhereClause> idBetween(
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

extension PrayerLogLocalQueryFilter
    on QueryBuilder<PrayerLogLocal, PrayerLogLocal, QFilterCondition> {
  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      dayEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'day',
        value: value,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      dayGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'day',
        value: value,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      dayLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'day',
        value: value,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      dayBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'day',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      prayerEqualTo(
    PrayerName value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'prayer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      prayerGreaterThan(
    PrayerName value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'prayer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      prayerLessThan(
    PrayerName value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'prayer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      prayerBetween(
    PrayerName lower,
    PrayerName upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'prayer',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      prayerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'prayer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      prayerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'prayer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      prayerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'prayer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      prayerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'prayer',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      prayerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'prayer',
        value: '',
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      prayerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'prayer',
        value: '',
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      remoteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      remoteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remoteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      remoteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      remoteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      statusEqualTo(
    PrayerStatus value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      statusGreaterThan(
    PrayerStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      statusLessThan(
    PrayerStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      statusBetween(
    PrayerStatus lower,
    PrayerStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension PrayerLogLocalQueryObject
    on QueryBuilder<PrayerLogLocal, PrayerLogLocal, QFilterCondition> {}

extension PrayerLogLocalQueryLinks
    on QueryBuilder<PrayerLogLocal, PrayerLogLocal, QFilterCondition> {}

extension PrayerLogLocalQuerySortBy
    on QueryBuilder<PrayerLogLocal, PrayerLogLocal, QSortBy> {
  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy> sortByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.asc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy> sortByDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.desc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy> sortByPrayer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayer', Sort.asc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy>
      sortByPrayerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayer', Sort.desc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy> sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy>
      sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension PrayerLogLocalQuerySortThenBy
    on QueryBuilder<PrayerLogLocal, PrayerLogLocal, QSortThenBy> {
  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy> thenByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.asc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy> thenByDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.desc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy> thenByPrayer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayer', Sort.asc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy>
      thenByPrayerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayer', Sort.desc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy> thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy>
      thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension PrayerLogLocalQueryWhereDistinct
    on QueryBuilder<PrayerLogLocal, PrayerLogLocal, QDistinct> {
  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QDistinct> distinctByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'day');
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QDistinct> distinctByPrayer(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'prayer', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QDistinct> distinctByRemoteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerLogLocal, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension PrayerLogLocalQueryProperty
    on QueryBuilder<PrayerLogLocal, PrayerLogLocal, QQueryProperty> {
  QueryBuilder<PrayerLogLocal, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PrayerLogLocal, DateTime, QQueryOperations> dayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'day');
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerName, QQueryOperations> prayerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'prayer');
    });
  }

  QueryBuilder<PrayerLogLocal, String, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<PrayerLogLocal, PrayerStatus, QQueryOperations>
      statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<PrayerLogLocal, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPrayerTimeLocalCollection on Isar {
  IsarCollection<PrayerTimeLocal> get prayerTimeLocals => this.collection();
}

const PrayerTimeLocalSchema = CollectionSchema(
  name: r'PrayerTimeLocal',
  id: -1750505837621583774,
  properties: {
    r'day': PropertySchema(
      id: 0,
      name: r'day',
      type: IsarType.dateTime,
    ),
    r'hijriDate': PropertySchema(
      id: 1,
      name: r'hijriDate',
      type: IsarType.string,
    ),
    r'prayer': PropertySchema(
      id: 2,
      name: r'prayer',
      type: IsarType.string,
      enumMap: _PrayerTimeLocalprayerEnumValueMap,
    ),
    r'time': PropertySchema(
      id: 3,
      name: r'time',
      type: IsarType.string,
    ),
    r'userId': PropertySchema(
      id: 4,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _prayerTimeLocalEstimateSize,
  serialize: _prayerTimeLocalSerialize,
  deserialize: _prayerTimeLocalDeserialize,
  deserializeProp: _prayerTimeLocalDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _prayerTimeLocalGetId,
  getLinks: _prayerTimeLocalGetLinks,
  attach: _prayerTimeLocalAttach,
  version: '3.1.0+1',
);

int _prayerTimeLocalEstimateSize(
  PrayerTimeLocal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.hijriDate;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.prayer.name.length * 3;
  bytesCount += 3 + object.time.length * 3;
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _prayerTimeLocalSerialize(
  PrayerTimeLocal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.day);
  writer.writeString(offsets[1], object.hijriDate);
  writer.writeString(offsets[2], object.prayer.name);
  writer.writeString(offsets[3], object.time);
  writer.writeString(offsets[4], object.userId);
}

PrayerTimeLocal _prayerTimeLocalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PrayerTimeLocal();
  object.day = reader.readDateTime(offsets[0]);
  object.hijriDate = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.prayer =
      _PrayerTimeLocalprayerValueEnumMap[reader.readStringOrNull(offsets[2])] ??
          PrayerName.fajr;
  object.time = reader.readString(offsets[3]);
  object.userId = reader.readString(offsets[4]);
  return object;
}

P _prayerTimeLocalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (_PrayerTimeLocalprayerValueEnumMap[
              reader.readStringOrNull(offset)] ??
          PrayerName.fajr) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PrayerTimeLocalprayerEnumValueMap = {
  r'fajr': r'fajr',
  r'dhuhr': r'dhuhr',
  r'asr': r'asr',
  r'maghrib': r'maghrib',
  r'isha': r'isha',
};
const _PrayerTimeLocalprayerValueEnumMap = {
  r'fajr': PrayerName.fajr,
  r'dhuhr': PrayerName.dhuhr,
  r'asr': PrayerName.asr,
  r'maghrib': PrayerName.maghrib,
  r'isha': PrayerName.isha,
};

Id _prayerTimeLocalGetId(PrayerTimeLocal object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _prayerTimeLocalGetLinks(PrayerTimeLocal object) {
  return [];
}

void _prayerTimeLocalAttach(
    IsarCollection<dynamic> col, Id id, PrayerTimeLocal object) {
  object.id = id;
}

extension PrayerTimeLocalQueryWhereSort
    on QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QWhere> {
  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PrayerTimeLocalQueryWhere
    on QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QWhereClause> {
  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterWhereClause>
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

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterWhereClause> idBetween(
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

extension PrayerTimeLocalQueryFilter
    on QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QFilterCondition> {
  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      dayEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'day',
        value: value,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      dayGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'day',
        value: value,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      dayLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'day',
        value: value,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      dayBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'day',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      hijriDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hijriDate',
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      hijriDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hijriDate',
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      hijriDateEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hijriDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      hijriDateGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hijriDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      hijriDateLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hijriDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      hijriDateBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hijriDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      hijriDateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hijriDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      hijriDateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hijriDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      hijriDateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hijriDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      hijriDateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hijriDate',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      hijriDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hijriDate',
        value: '',
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      hijriDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hijriDate',
        value: '',
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      prayerEqualTo(
    PrayerName value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'prayer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      prayerGreaterThan(
    PrayerName value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'prayer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      prayerLessThan(
    PrayerName value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'prayer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      prayerBetween(
    PrayerName lower,
    PrayerName upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'prayer',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      prayerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'prayer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      prayerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'prayer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      prayerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'prayer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      prayerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'prayer',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      prayerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'prayer',
        value: '',
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      prayerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'prayer',
        value: '',
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      timeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'time',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      timeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'time',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      timeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'time',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      timeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'time',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      timeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'time',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      timeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'time',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      timeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'time',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      timeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'time',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      timeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'time',
        value: '',
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      timeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'time',
        value: '',
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
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

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension PrayerTimeLocalQueryObject
    on QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QFilterCondition> {}

extension PrayerTimeLocalQueryLinks
    on QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QFilterCondition> {}

extension PrayerTimeLocalQuerySortBy
    on QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QSortBy> {
  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy> sortByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.asc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy> sortByDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.desc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy>
      sortByHijriDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hijriDate', Sort.asc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy>
      sortByHijriDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hijriDate', Sort.desc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy> sortByPrayer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayer', Sort.asc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy>
      sortByPrayerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayer', Sort.desc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy> sortByTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.asc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy>
      sortByTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.desc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension PrayerTimeLocalQuerySortThenBy
    on QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QSortThenBy> {
  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy> thenByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.asc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy> thenByDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.desc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy>
      thenByHijriDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hijriDate', Sort.asc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy>
      thenByHijriDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hijriDate', Sort.desc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy> thenByPrayer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayer', Sort.asc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy>
      thenByPrayerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prayer', Sort.desc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy> thenByTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.asc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy>
      thenByTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.desc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension PrayerTimeLocalQueryWhereDistinct
    on QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QDistinct> {
  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QDistinct> distinctByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'day');
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QDistinct> distinctByHijriDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hijriDate', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QDistinct> distinctByPrayer(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'prayer', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QDistinct> distinctByTime(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'time', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension PrayerTimeLocalQueryProperty
    on QueryBuilder<PrayerTimeLocal, PrayerTimeLocal, QQueryProperty> {
  QueryBuilder<PrayerTimeLocal, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PrayerTimeLocal, DateTime, QQueryOperations> dayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'day');
    });
  }

  QueryBuilder<PrayerTimeLocal, String?, QQueryOperations> hijriDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hijriDate');
    });
  }

  QueryBuilder<PrayerTimeLocal, PrayerName, QQueryOperations> prayerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'prayer');
    });
  }

  QueryBuilder<PrayerTimeLocal, String, QQueryOperations> timeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'time');
    });
  }

  QueryBuilder<PrayerTimeLocal, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
