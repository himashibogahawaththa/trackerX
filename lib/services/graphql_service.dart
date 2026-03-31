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
}