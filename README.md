# EcoPay

EcoPay is a cross border remittance app built with Flutter. It lets a user sign in, see their wallet balance, get a live quote for sending US dollars to family in Southern Africa or the UK, and confirm the transfer.

> This repository is a clean rebuild of my earlier EcoPay project, written in 2026 with a focus on code quality, security and tests.

## Features

* **Sign in** with email and a 4 digit PIN, with the session token kept in secure storage (Keychain on iOS, EncryptedSharedPreferences on Android)
* **Wallet** showing the current balance and recent transfers
* **Live exchange rates** from a public rates API, cached for 10 minutes
* **Transparent quotes** showing the amount sent, fee, exchange rate, total and amount received
* **Quote expiry** after 5 minutes so users never send at a stale rate
* **Balance checks** that block transfers the wallet cannot cover
* Receive currencies: ZAR, ZMW, BWP, MWK and GBP

## How it is built

| Layer | Folder | What it does |
| --- | --- | --- |
| Screens | `lib/screens` | Login, home (wallet) and send money screens |
| State | `lib/state` | `AuthProvider` and `WalletProvider` using the Provider package |
| Services | `lib/services` | Exchange rates (HTTP), authentication (secure storage), transfers |
| Models | `lib/models` | `Quote` and `Transfer` |
| Utilities | `lib/utils` | Money formatting and the fee calculator |

Design choices:

* **Money is stored in whole cents (`int`)**, never `double`, to avoid rounding errors.
* **Fees** are a flat USD 1.50 plus 2%, capped at USD 25.00 (`FeeCalculator`).
* **Services are injected**, so they can be swapped for a real backend or mocked in tests. `TransferRepository` currently simulates the backend in memory.
* **Errors are explicit** (`ExchangeRateException`, `InsufficientFundsException`, `QuoteExpiredException`) and shown to the user in plain language.

## Tests

```bash
flutter test
```

* `money_and_fees_test.dart`: parsing, formatting and fee rules
* `quote_and_repository_test.dart`: quote maths, expiry and balance checks
* `exchange_rate_service_test.dart`: caching and error handling with a mocked HTTP client
* `widget_test.dart`: sign in flow and form validation

## Run it

```bash
flutter create . --org com.jephtahmutore --project-name ecopay   # generates android and ios folders
flutter pub get
flutter test
flutter run
```

## Next steps

* Connect `TransferRepository` to a real REST API with OAuth 2.0 tokens
* Biometric sign in and certificate pinning
* KYC onboarding flow
* Push notifications when a transfer is collected

## Author

Jeddidah Mutore, software engineer. GitHub: [jephtahmutore](https://github.com/jephtahmutore)
