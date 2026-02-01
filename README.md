# nerobot

A new Flutter project.

## Деплой в App Store (пошагово)

### Шаг 1. Apple Developer Program

- Зайди на [developer.apple.com](https://developer.apple.com).
- Войди под Apple ID → **Account** → **Membership**.
- Если аккаунта нет: **Enroll** → выбери тип (Individual или Organization), оплати подписку (~99$/год).
- Дождись активации (обычно 24–48 часов для проверки).

---

### Шаг 2. Настройка проекта в Xcode

- Открой iOS-часть проекта в Xcode:
  ```bash
  open ios/Runner.xcworkspace
  ```
- В левой панели выбери проект **Runner** (синяя иконка).
- Вкладка **Signing & Capabilities**:
  - Поставь галочку **Automatically manage signing**.
  - **Team** — выбери свою команду (появится после входа в Xcode под Apple ID с активной подпиской).
  - **Bundle Identifier** — уникальный ID, например `com.yourcompany.nerobot` (должен совпадать с тем, что будет в App Store Connect).
- Целевая версия iOS: в **General** → **Minimum Deployments** выбери нужную (например, iOS 12.0 или выше).

---

### Шаг 3. Info.plist и права доступа

- В Xcode открой `ios/Runner/Info.plist` (или через **Runner** → **Info**).
- Проверь/заполни:
  - **CFBundleShortVersionString** — версия для пользователей (например, `1.0.0`).
  - **CFBundleVersion** — build-номер (целое число, растёт с каждой загрузкой в App Store).
- Если приложение использует камеру, микрофон, геолокацию и т.д., в Info.plist должны быть ключи с описанием **на английском**, иначе ревью отклонит:
  - Камера: `NSCameraUsageDescription`
  - Микрофон: `NSMicrophoneUsageDescription`
  - Геолокация: `NSLocationWhenInUseUsageDescription` и/или `NSLocationAlwaysUsageDescription`
- В Flutter эти ключи можно задать в `ios/Runner/Info.plist` вручную или через плагины.

---

### Шаг 4. Сборка релизной версии

**Вариант A — через Flutter:**

```bash
flutter clean
flutter pub get
flutter build ipa
```

Готовый `.ipa` будет в `build/ios/ipa/`.

**Вариант B — через Xcode:**

- В Xcode выбери схему **Runner** и устройство **Any iOS Device (arm64)**.
- Меню **Product** → **Archive**.
- Дождись окончания архивации; откроется окно **Organizer** с архивом.

---

### Шаг 5. App Store Connect — создание приложения

- Зайди на [appstoreconnect.apple.com](https://appstoreconnect.apple.com) под тем же Apple ID.
- **My Apps** → **+** → **New App**.
- Укажи:
  - **Platforms**: iOS.
  - **Name** — название в каталоге.
  - **Primary Language**.
  - **Bundle ID** — выбери из списка (должен быть создан в [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Identifiers**, если нет — создай с тем же Bundle ID, что в Xcode).
  - **SKU** — свой внутренний код (например, `nerobot-001`).
- Сохрани. Перейди в карточку приложения.

---

### Шаг 6. Метаданные и скриншоты в App Store Connect

В карточке приложения открой версию (например, **1.0.0**) и заполни:

- **Screenshots** — обязательны для каждого размера iPhone/iPad, который поддерживаешь. Делай в симуляторе или на устройстве (требуемые размеры подскажет App Store Connect).
- **Promotional Text** (по желанию) — короткий текст над описанием.
- **Description** — полное описание приложения.
- **Keywords** — через запятую, без пробелов после запятой.
- **Support URL** — ссылка на поддержку.
- **Marketing URL** (по желанию).
- **Version** — должен совпадать с CFBundleShortVersionString.
- **Copyright**.
- **Age Rating** — пройти анкету и получить рейтинг.
- **App Privacy** — ссылка на политику конфиденциальности (если собираешь данные).

В разделе **Pricing and Availability** выбери страны и цену (или Free).

---

### Что ещё настроить в App Store Connect

Сделай это до первой отправки на ревью (или по мере появления предупреждений в интерфейсе).

**1. Соглашения, налоги и банк (Agreements, Tax, and Banking)**

- В верхнем меню: **Users and Access** → вкладка **Agreements, Tax, and Banking** (или **App Store Connect** → **Agreements**).
- Должен быть активный **Paid Applications** или **Free Applications** agreement — если статус «Action Needed», нажми и прими соглашение.
- **Contact Info** — укажи контактное лицо, телефон, email.
- **Banking** — добавь банковские реквизиты (нужно для платных приложений и подписок; для только бесплатных можно не заполнять, но соглашение принять нужно).
- **Tax** — заполни налоговые формы (W-9 для США, W-8BEN для других стран и т.д.). Без этого приложение могут не допустить к продаже.

**2. Информация для ревью (App Review Information)**

- В карточке приложения открой версию (например, 1.0.0).
- Прокрути до блока **App Review Information**.
- **Contact Information** — телефон и email человека, с кем может связаться Apple при вопросах по ревью.
- **Demo Account** — если для входа нужен логин/пароль, создай тестовый аккаунт и укажи его здесь (Username и Password). Иначе ревью отклонит с просьбой предоставить доступ.
- **Notes** — любые пояснения для ревьюеров (например, «тестовый платёж не списывается», куда нажимать для проверки функции и т.д.).

**3. Экспорт и соответствие (Export Compliance, Content Rights и т.д.)**

- В той же версии найди **Export Compliance**.
- Если приложение не использует шифрование (кроме стандартного HTTPS) — можно выбрать **No** или «Uses encryption: No». Иначе укажи, что используется, и при необходимости заполни форму.
- **Content Rights** — подтверди, что у тебя есть права на контент (музыка, картинки и т.д.).
- **Advertising Identifier (IDFA)** — отметь, использует ли приложение рекламный идентификатор (реклама, аналитика по рекламе). От этого зависят пункты в App Privacy.

**4. Категория и подзаголовок**

- В **App Information** (в карточке приложения, слева или в общих настройках): выбери **Primary Category** и при необходимости **Secondary Category**.
- **Subtitle** — короткая строка под названием в каталоге (до 30 символов). Заполняется в метаданных версии.

**5. Локализация**

- Если нужен не только основной язык: в метаданных версии добавь **App Store Localization** — язык и переведённые название, описание, ключевые слова, скриншоты для этого языка.

**6. TestFlight (по желанию)**

- Вкладка **TestFlight** в карточке приложения.
- После загрузки билда он попадает сюда; добавь **Internal Testing** (до 100 тестеров по email) или **External Testing** (до 10 000 по ссылке, нужен короткий ревью Apple).
- Удобно проверить установку и работу перед отправкой в продакшен.

**7. App Privacy**

- В карточке приложения: **App Privacy**.
- Нажми **Get Started** и ответь, какие данные собираешь (геолокация, контакты, идентификаторы и т.д.), с какой целью и передаются ли третьим лицам. Apple сформирует текст на странице приложения. Без заполнения приложение не примут на ревью, если собираются данные.

Проверь, что в версии нет жёлтых предупреждений и все обязательные поля заполнены — тогда кнопка **Add for Review** / **Submit for Review** станет доступна.

---

### Шаг 7. Загрузка билда в App Store Connect

**Если собирал через Xcode (Archive):**

- В **Organizer** выбери архив → **Distribute App**.
- **App Store Connect** → **Upload** → далее по шагам (подпись обычно автоматическая).
- После успешной загрузки подожди 5–15 минут, пока билд появится в App Store Connect.

**Если собирал через `flutter build ipa`:**

- Открой **Transporter** (из App Store в Mac) или Xcode → **Window** → **Organizer** → **Distribute App** и укажи путь к `.ipa` из `build/ios/ipa/`.
- Загрузи файл; билд появится в том же месте в App Store Connect.

В карточке версии в **Build** выбери загруженный билд. Без выбранного билда на ревью отправить нельзя.

---

### Шаг 8. Отправка на ревью и релиз

- В App Store Connect проверь, что у версии выбран **Build**, заполнены все обязательные поля и нет предупреждений.
- Нажми **Add for Review** / **Submit for Review**.
- Ответь на вопросы экспорта (шифрование и т.д.), если появятся.
- Статус сменится на **Waiting for Review**, затем **In Review**. Обычно 24–48 часов.
- При одобрении статус станет **Ready for Sale** — приложение появится в App Store (или в выбранную дату, если настроил отложенный релиз).
- При отклонении придёт письмо с причиной; исправь и отправь новую версию/билд.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
