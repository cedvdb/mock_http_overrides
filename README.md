# MockHttpOverrides

allow network images during unit tests


```
  setUp(() async {
    HttpOverrides.global = MockHttpOverrides();
  });
```

# Credit

The code is copied from: https://stackoverflow.com/a/49167253/4299560