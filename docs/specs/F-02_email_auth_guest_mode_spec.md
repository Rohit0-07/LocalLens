# Feature Spec: F-02 Email Auth, Guest Mode & Resend Timer Engine

## 1. Overview
This specification defines the extension to `F-02` (Authentication & Anonymous Identity Engine) covering Email OTP authentication, Guest Sessions, 60-second Resend OTP Timer, and Guest Authorization Interception.

---

## 2. Backend Requirements (FastAPI + SQLAlchemy)

### 2.1 Database Models (`backend/app/features/auth/models.py`)
- `User`: add `email: Mapped[str | None] = mapped_column(String(255), unique=True, nullable=True, index=True)`. Ensure `phone` remains `nullable=True`.
- `OtpCode`: add `email: Mapped[str | None] = mapped_column(String(255), nullable=True, index=True)`. Ensure `phone` is `nullable=True` so `OtpCode` supports either `phone` or `email`.

### 2.2 Schemas (`backend/app/features/auth/schemas.py`)
- `EmailOtpRequest`: `email: EmailStr`.
- `EmailOtpVerify`: `email: EmailStr`, `code: str = Field(min_length=6, max_length=6)`.
- `TokenResponse`: add `is_guest: bool = False`.
- `UserOut`: add `email: str | None = None`, `is_guest: bool = False`.

### 2.3 Endpoints (`backend/app/features/auth/router.py` & `service.py`)
- `POST /auth/email/request-otp`:
  - Validates `email`.
  - Clears existing `OtpCode` for email.
  - Creates hashed 6-digit OTP code (`OtpCode(email=email, code_hash=..., expires_at=...)`).
  - Returns `204 No Content`.
- `POST /auth/email/verify-otp`:
  - Validates latest active OTP for `email`.
  - Finds or creates `User(email=email)`.
  - Deletes used `OtpCode`.
  - Generates JWT token with `sub=str(user.id)`, `is_guest=False`.
  - Derives `anon_id`.
  - Returns `TokenResponse(access_token=..., user_id=user.id, anonymous_identity=anon_id, anon_id=anon_id, is_guest=False)`.
- `POST /auth/guest`:
  - Generates a guest session token.
  - `access_token` JWT contains `sub="guest:<uuid>"`, `is_guest=True`.
  - Returns `TokenResponse(access_token=..., user_id="guest:<uuid>", anonymous_identity="guest_anon", anon_id="guest_anon", is_guest=True)`.
- `GET /auth/me`:
  - For authenticated user, returns `UserOut` with `email`, `phone`, `is_guest=False`.
  - For guest token, returns `UserOut(id="guest:...", phone=None, email=None, anonymous_identity="guest_anon", anon_id="guest_anon", is_guest=True)`.

### 2.4 Authorization Guards
- Guests (`is_guest=True`) MUST be rejected on write/action endpoints:
  - `POST /issues` -> `403 Forbidden` (`code="guest_restricted"`, message="Sign in required to create issues").
  - `POST /issues/{id}/upvote` -> `403 Forbidden` (`code="guest_restricted"`, message="Sign in required to upvote").
  - `POST /issues/{id}/quorum-vote` -> `403 Forbidden` (`code="guest_restricted"`, message="Sign in required to vote on quorum").

---

## 3. Frontend Requirements (Flutter + Riverpod)

### 3.1 Sign In Screen (`app/lib/features/auth/presentation/screens/sign_in_screen.dart`)
- **Mode Switcher**: Clean M3 `SegmentedButton` or `TabBar` allowing user to select **Phone** or **Email**.
- **Phone Tab**: E.164 phone input (`+91 ...`).
- **Email Tab**: Email input with RFC email validation regex (`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`).
- **OTP Timer**: When OTP is requested, display a **60-second countdown timer** ("Resend OTP in 59s"). Disable "Resend OTP" until counter reaches 0. When timer hits 0, enable "Resend OTP" button.
- **Continue as Guest**: Secondary M3 `OutlinedButton` below sign in options ("Continue as Guest"). Triggers `POST /auth/guest`, saves guest token to `LocalStore`, navigates to Home Feed.

### 3.2 Guest Guard Bottom Sheet / Dialog (`app/lib/features/auth/presentation/widgets/guest_guard.dart`)
- Clean M3 `AlertDialog` or `BottomSheet` triggered when a guest attempts restricted actions.
- Elements: Title ("Sign in required"), body ("Create an account or sign in to participate in civic reporting."), primary action ("Sign In" -> navigates to `/sign-in`), secondary action ("Cancel").
- Styling: Minimalist, clean M3, no gradients, no emojis.

---

## 4. Design System & Aesthetics Guidelines
- Use tokens from `app_colors.dart` and `app_theme.dart`.
- NO emojis anywhere in UI text.
- NO colorful gradients. Use flat, subtle M3 surfaces and standard primary/secondary colors.
