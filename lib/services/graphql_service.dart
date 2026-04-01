import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLService {
  static final HttpLink httpLink = HttpLink('https://countries.trevorblades.com/');

  static ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );

  static const String getCountriesQuery = """
    query GetCountries {
      countries {
        name
        capital
        emoji
        code
      }
    }
  """;

  static const String getCountryByCodeQuery = """
    query GetCountryByCode(\$code: ID!) {
      country(code: \$code) {
        name
        capital
        emoji
        code
      }
    }
  """;

  static Future<Map<String, dynamic>?> fetchCountryByCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) return null;

    final result = await client.value.query(
      QueryOptions(
        document: gql(getCountryByCodeQuery),
        variables: {'code': normalizedCode},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final dynamic country = result.data?['country'];
    if (country is Map<String, dynamic>) return country;
    return null;
  }
}