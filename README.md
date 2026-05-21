# work_erp_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Build Android App Bundle (Play Store)

1. Crie uma keystore de upload (uma vez):

```bash
keytool -genkeypair -v \
  -keystore android/upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

2. Crie o arquivo `android/key.properties` baseado em `android/key.properties.example`:

```properties
storeFile=upload-keystore.jks
storePassword=SUA_SENHA_DA_KEYSTORE
keyAlias=upload
keyPassword=SUA_SENHA_DA_CHAVE
```

3. Gere o `.aab`:

```bash
flutter build appbundle --release
```

4. Arquivo gerado:

`build/app/outputs/bundle/release/app-release.aab`
