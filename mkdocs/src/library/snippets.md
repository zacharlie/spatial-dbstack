# Snippets

## GraphQL

https://www.graphile.org/postgraphile/examples/

Basic query

```js
{allNe10MAdmin0Countries{nodes{name}}}
```

Retrieve schema details (list types)

```js
{
  __schema {
    types {
      name
      kind
      fields {
        name
      }
    }
  }
}
```

Retrieve details for type

```js
{
  __type(name: "Query") {
    name
    kind
    description
    fields {
      name
    }
  }
}
```

Retrieve objects with specified fields

```js
{
  allSampleCountries {
    edges {
      node {
        id
        name
      }
    }
  }
}
```

Named query

```js
query getCountries {
  allSampleCountries {
    nodes {
      id
      name
    }
  }
}
```

Retrieve item by id

```js
{
  sampleCountryById (id: 6) {
    name
  }
}
```

Retrieve object with conditional filter

```js
{
  allSampleCountries(condition: {name: "Lesotho"}) {
    edges {
      node {
        id
        sovereignt
        name
      }
    }
  }
}
```
