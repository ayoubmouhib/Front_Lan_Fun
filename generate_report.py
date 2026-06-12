#!/usr/bin/env python3
"""
LinguaConnect — Project Technical Report Generator
Produces a professional PDF for the mobile-application-development presentation.
"""

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm, cm
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, PageBreak, KeepTogether
)
from reportlab.platypus import ListFlowable, ListItem

# ─── Colours ─────────────────────────────────────────────────────────────────
INDIGO   = colors.HexColor("#6366F1")
EMERALD  = colors.HexColor("#10B981")
SLATE    = colors.HexColor("#1E293B")
LIGHT    = colors.HexColor("#F1F5F9")
MID      = colors.HexColor("#94A3B8")
WHITE    = colors.white
BLACK    = colors.HexColor("#0F172A")
ORANGE   = colors.HexColor("#F59E0B")
RED      = colors.HexColor("#EF4444")
PURPLE   = colors.HexColor("#8B5CF6")

OUTPUT = "/home/yoyo/MProjects/flutter1/flutter5/testapp/Test/application/LinguaConnect_Technical_Report.pdf"

# ─── Document setup ───────────────────────────────────────────────────────────
doc = SimpleDocTemplate(
    OUTPUT,
    pagesize=A4,
    rightMargin=20*mm, leftMargin=20*mm,
    topMargin=25*mm, bottomMargin=20*mm,
    title="LinguaConnect – Technical Project Report",
    author="LinguaConnect Dev Team",
)

W = A4[0] - 40*mm   # usable width

# ─── Styles ───────────────────────────────────────────────────────────────────
styles = getSampleStyleSheet()

def S(name, **kw):
    return ParagraphStyle(name, **kw)

cover_title  = S("CoverTitle",  fontSize=32, leading=38, textColor=WHITE,   fontName="Helvetica-Bold",  alignment=TA_CENTER)
cover_sub    = S("CoverSub",    fontSize=14, leading=20, textColor=WHITE,    fontName="Helvetica",       alignment=TA_CENTER)
cover_meta   = S("CoverMeta",   fontSize=10, leading=14, textColor=colors.HexColor("#CBD5E1"), fontName="Helvetica", alignment=TA_CENTER)

h1           = S("H1",  fontSize=18, leading=24, textColor=INDIGO,  fontName="Helvetica-Bold",  spaceBefore=14, spaceAfter=6)
h2           = S("H2",  fontSize=13, leading=18, textColor=SLATE,   fontName="Helvetica-Bold",  spaceBefore=10, spaceAfter=4)
h3           = S("H3",  fontSize=11, leading=15, textColor=INDIGO,  fontName="Helvetica-Bold",  spaceBefore=6,  spaceAfter=3)
body         = S("Body",fontSize=9,  leading=14, textColor=BLACK,   fontName="Helvetica",       spaceAfter=4,   alignment=TA_JUSTIFY)
body_bullet  = S("BB",  fontSize=9,  leading=14, textColor=BLACK,   fontName="Helvetica",       leftIndent=12,  spaceAfter=2)
mono         = S("Mono",fontSize=8,  leading=12, textColor=BLACK,   fontName="Courier",         backColor=LIGHT, leftIndent=8, rightIndent=8, spaceAfter=4)
mono_label   = S("ML",  fontSize=7.5,leading=11, textColor=MID,     fontName="Courier-Bold",    spaceAfter=1)
caption      = S("Cap", fontSize=8,  leading=11, textColor=MID,     fontName="Helvetica-Oblique", alignment=TA_CENTER, spaceAfter=6)
note         = S("Note",fontSize=8,  leading=12, textColor=colors.HexColor("#475569"), fontName="Helvetica-Oblique", leftIndent=8)

def HR(color=INDIGO, thickness=1):
    return HRFlowable(width="100%", thickness=thickness, color=color, spaceAfter=6, spaceBefore=4)

def SPACE(h=4):
    return Spacer(1, h*mm)

def heading(text, style=h1):
    return Paragraph(text, style)

def para(text, style=body):
    return Paragraph(text, style)

def bullet(items, style=body_bullet):
    return [Paragraph(f"• {i}", style) for i in items]

def code(lines, label=None):
    out = []
    if label:
        out.append(Paragraph(label, mono_label))
    block = "<br/>".join(lines)
    out.append(Paragraph(block, mono))
    return out

def colored_box(text, bg=INDIGO, fg=WHITE, font_size=9):
    style = S("cb", fontSize=font_size, textColor=fg, fontName="Helvetica-Bold",
               backColor=bg, alignment=TA_CENTER, leading=13)
    return Paragraph(text, style)

# ─── Table helpers ────────────────────────────────────────────────────────────
def info_table(rows, col_widths=None):
    if col_widths is None:
        col_widths = [55*mm, W - 55*mm]
    t = Table(rows, colWidths=col_widths)
    t.setStyle(TableStyle([
        ("BACKGROUND",  (0,0), (0,-1), LIGHT),
        ("TEXTCOLOR",   (0,0), (0,-1), SLATE),
        ("FONTNAME",    (0,0), (0,-1), "Helvetica-Bold"),
        ("FONTNAME",    (1,0), (1,-1), "Helvetica"),
        ("FONTSIZE",    (0,0), (-1,-1), 8.5),
        ("LEADING",     (0,0), (-1,-1), 13),
        ("ROWBACKGROUNDS", (0,0), (-1,-1), [WHITE, LIGHT]),
        ("GRID",        (0,0), (-1,-1), 0.4, colors.HexColor("#E2E8F0")),
        ("VALIGN",      (0,0), (-1,-1), "TOP"),
        ("LEFTPADDING", (0,0), (-1,-1), 6),
        ("RIGHTPADDING",(0,0), (-1,-1), 6),
        ("TOPPADDING",  (0,0), (-1,-1), 4),
        ("BOTTOMPADDING",(0,0), (-1,-1), 4),
    ]))
    return t

def header_table(headers, rows, col_widths=None):
    if col_widths is None:
        col_widths = [W / len(headers)] * len(headers)
    all_rows = [headers] + rows
    t = Table(all_rows, colWidths=col_widths)
    t.setStyle(TableStyle([
        ("BACKGROUND",  (0,0), (-1,0), INDIGO),
        ("TEXTCOLOR",   (0,0), (-1,0), WHITE),
        ("FONTNAME",    (0,0), (-1,0), "Helvetica-Bold"),
        ("FONTNAME",    (0,1), (-1,-1), "Helvetica"),
        ("FONTSIZE",    (0,0), (-1,-1), 8.5),
        ("LEADING",     (0,0), (-1,-1), 13),
        ("ROWBACKGROUNDS", (0,1), (-1,-1), [WHITE, LIGHT]),
        ("GRID",        (0,0), (-1,-1), 0.4, colors.HexColor("#E2E8F0")),
        ("VALIGN",      (0,0), (-1,-1), "TOP"),
        ("LEFTPADDING", (0,0), (-1,-1), 6),
        ("RIGHTPADDING",(0,0), (-1,-1), 6),
        ("TOPPADDING",  (0,0), (-1,-1), 4),
        ("BOTTOMPADDING",(0,0), (-1,-1), 4),
    ]))
    return t

# ─── Cover page ───────────────────────────────────────────────────────────────
def cover_page():
    cover_bg = Table(
        [[colored_box("LinguaConnect", bg=INDIGO, fg=WHITE, font_size=36)]],
        colWidths=[W]
    )
    cover_bg.setStyle(TableStyle([
        ("BACKGROUND",  (0,0), (-1,-1), INDIGO),
        ("TOPPADDING",  (0,0), (-1,-1), 28),
        ("BOTTOMPADDING",(0,0), (-1,-1), 28),
        ("LEFTPADDING", (0,0), (-1,-1), 10),
        ("RIGHTPADDING",(0,0), (-1,-1), 10),
        ("ROUNDEDCORNERS", [8]),
    ]))

    elems = []
    elems.append(SPACE(8))
    elems.append(cover_bg)
    elems.append(SPACE(4))

    subtitle_tbl = Table(
        [[colored_box("Learn Languages, Make Friends", bg=EMERALD, fg=WHITE, font_size=13)]],
        colWidths=[W]
    )
    subtitle_tbl.setStyle(TableStyle([
        ("BACKGROUND",  (0,0), (-1,-1), EMERALD),
        ("TOPPADDING",  (0,0), (-1,-1), 8),
        ("BOTTOMPADDING",(0,0), (-1,-1), 8),
        ("ROUNDEDCORNERS", [6]),
    ]))
    elems.append(subtitle_tbl)
    elems.append(SPACE(10))

    meta_data = [
        ["Project",      "LinguaConnect — Full-Stack Language-Learning App"],
        ["Stack",        "Flutter (Dart) + NestJS (TypeScript) + MySQL"],
        ["Architecture", "GetX MVC · REST + WebSocket · Repository Pattern"],
        ["Course",       "Mobile Application Development with Flutter"],
        ["Date",         "June 2026"],
    ]
    t = Table(meta_data, colWidths=[35*mm, W - 35*mm])
    t.setStyle(TableStyle([
        ("BACKGROUND",  (0,0), (0,-1), colors.HexColor("#EEF2FF")),
        ("FONTNAME",    (0,0), (0,-1), "Helvetica-Bold"),
        ("FONTNAME",    (1,0), (1,-1), "Helvetica"),
        ("FONTSIZE",    (0,0), (-1,-1), 9.5),
        ("LEADING",     (0,0), (-1,-1), 15),
        ("GRID",        (0,0), (-1,-1), 0.5, colors.HexColor("#C7D2FE")),
        ("VALIGN",      (0,0), (-1,-1), "MIDDLE"),
        ("LEFTPADDING", (0,0), (-1,-1), 8),
        ("TOPPADDING",  (0,0), (-1,-1), 6),
        ("BOTTOMPADDING",(0,0), (-1,-1), 6),
    ]))
    elems.append(t)
    elems.append(SPACE(8))

    desc = para(
        "This document is a comprehensive technical reference for the <b>LinguaConnect</b> "
        "mobile application. It covers the project architecture, Flutter implementation details, "
        "data flow between backend and frontend, state management with GetX, real-time "
        "communication via WebSocket, and an annotated walkthrough of every major screen and "
        "feature — intended for presentation to the mobile application development course instructor.",
        body
    )
    elems.append(desc)
    elems.append(PageBreak())
    return elems

# ─── Table of Contents ────────────────────────────────────────────────────────
def toc():
    elems = []
    elems.append(heading("Table of Contents"))
    elems.append(HR())
    toc_items = [
        ("1", "Project Overview & Objectives"),
        ("2", "Technology Stack"),
        ("3", "Project Architecture (Layered)"),
        ("4", "Flutter Project Structure"),
        ("5", "Application Entry Point — main.dart"),
        ("6", "Configuration — constants, theme, routes"),
        ("7", "Data Layer: Models, APIs, Repositories"),
        ("8", "State Management with GetX"),
        ("9", "Bindings — Dependency Injection"),
        ("10", "Navigation & Data Transfer Between Screens"),
        ("11", "Real-Time Communication: WebSocket Service"),
        ("12", "Authentication Flow (Splash → Login → Home)"),
        ("13", "Onboarding Screens"),
        ("14", "Home Screen"),
        ("15", "Conversations & Chat"),
        ("16", "Voice & Video Calls (LiveKit)"),
        ("17", "Matching System"),
        ("18", "Quiz & Games Features"),
        ("19", "Vocabulary Feature"),
        ("20", "Profile & Settings"),
        ("21", "Reusable Widgets"),
        ("22", "Backend: NestJS REST API"),
        ("23", "Backend: WebSocket Gateway"),
        ("24", "Database Entities & Relationships"),
        ("25", "Key Flutter Patterns Used"),
        ("26", "Summary & Conclusion"),
    ]
    rows = [[Paragraph(f"<b>{n}.</b>", body_bullet), Paragraph(title, body_bullet)]
            for n, title in toc_items]
    t = Table(rows, colWidths=[14*mm, W - 14*mm])
    t.setStyle(TableStyle([
        ("ROWBACKGROUNDS", (0,0), (-1,-1), [WHITE, LIGHT]),
        ("LEFTPADDING", (0,0), (-1,-1), 6),
        ("TOPPADDING",  (0,0), (-1,-1), 3),
        ("BOTTOMPADDING",(0,0), (-1,-1), 3),
        ("FONTSIZE",    (0,0), (-1,-1), 9),
    ]))
    elems.append(t)
    elems.append(PageBreak())
    return elems

# ─── Section 1 ────────────────────────────────────────────────────────────────
def section1():
    e = []
    e.append(heading("1. Project Overview & Objectives"))
    e.append(HR())
    e.append(para(
        "<b>LinguaConnect</b> is a cross-platform mobile application built with Flutter "
        "that connects language learners worldwide. Users are matched with native/proficient "
        "speakers of their target language, communicate via real-time text chat and "
        "audio/video calls, practice through quizzes and word games, and build a personal "
        "vocabulary list — all within a single app."
    ))
    e.append(SPACE(2))
    e.append(heading("Core Objectives", h2))
    e += bullet([
        "Connect language learners with language partners around the world.",
        "Enable real-time text messaging, typing indicators, and read receipts.",
        "Support high-quality audio and video calls powered by LiveKit.",
        "Provide gamified learning via vocabulary, quizzes, and word-matching games.",
        "Track user progress, XP, streaks, and leaderboards.",
        "Offer a smooth onboarding experience with modern splash and carousel screens.",
        "Support light/dark themes, Google Sign-In, and secure JWT authentication.",
    ])
    e.append(SPACE(2))
    e.append(heading("Supported Platforms", h2))
    e += bullet([
        "Android (primary target)",
        "iOS (architecture-compatible)",
        "Linux desktop (tested during development)",
    ])
    return e

# ─── Section 2 ────────────────────────────────────────────────────────────────
def section2():
    e = []
    e.append(heading("2. Technology Stack"))
    e.append(HR())
    rows = [
        ["Layer", "Technology", "Purpose"],
        ["Frontend", "Flutter 3.x (Dart)", "Cross-platform mobile UI"],
        ["State Mgmt", "GetX", "Reactive state, navigation, DI"],
        ["HTTP Client", "Dio", "REST calls, interceptors, auto token refresh"],
        ["WebSocket", "web_socket_channel", "Real-time messaging & events"],
        ["Auth", "flutter_secure_storage + SharedPreferences", "Secure token storage, preferences"],
        ["Audio/Video", "audioplayers + record + LiveKit SDK", "Playback, recording, calls"],
        ["Backend", "NestJS 11 (TypeScript)", "REST API & WebSocket gateway"],
        ["ORM", "TypeORM", "Database access & migrations"],
        ["Database", "MySQL", "Relational data storage"],
        ["Auth Backend", "Passport.js + JWT + Google OAuth2", "Login, tokens, Google Sign-In"],
        ["File Upload", "Multer (diskStorage)", "Profile photos, audio files"],
        ["Email", "Nodemailer", "Verification & password-reset emails"],
        ["Calls Infra", "LiveKit (self-hosted)", "WebRTC audio/video rooms"],
    ]
    t = header_table(
        [Paragraph(h, S("th", fontSize=9, textColor=WHITE, fontName="Helvetica-Bold", leading=12)) for h in rows[0]],
        [[Paragraph(c, body) for c in r] for r in rows[1:]],
        col_widths=[28*mm, 65*mm, W - 93*mm]
    )
    e.append(t)
    return e

# ─── Section 3 ────────────────────────────────────────────────────────────────
def section3():
    e = []
    e.append(heading("3. Project Architecture (Layered)"))
    e.append(HR())
    e.append(para(
        "The application follows a clean <b>layered architecture</b> that separates concerns into "
        "four distinct tiers on the frontend, mirroring a standard MVC/Repository approach."
    ))
    e.append(SPACE(2))
    layers = [
        ("Presentation Layer", INDIGO, [
            "Screens — full-page widgets the user interacts with",
            "Controllers — GetxController subclasses managing state",
            "Widgets — reusable UI building blocks",
            "Bindings — lazy dependency injection per route",
        ]),
        ("Data Layer", EMERALD, [
            "Models — Dart classes representing API JSON objects",
            "Repositories — business-logic wrappers over APIs",
            "Remote APIs — Dio-based HTTP clients (one per feature)",
            "Local Storage — StorageService (secure + SharedPreferences)",
        ]),
        ("Services Layer", PURPLE, [
            "WebSocketService — persistent WS connection, typed event streams",
            "AppController — global app state (theme, current user)",
        ]),
        ("Config Layer", ORANGE, [
            "AppConstants — API URL, storage keys, limits, app metadata",
            "AppTheme — light & dark Material 3 themes",
            "Routes — all named routes and GetPage registrations",
        ]),
    ]
    for title, color, items in layers:
        box = Table(
            [[colored_box(title, bg=color, fg=WHITE, font_size=10)]],
            colWidths=[W]
        )
        box.setStyle(TableStyle([
            ("BACKGROUND", (0,0), (-1,-1), color),
            ("TOPPADDING", (0,0), (-1,-1), 5),
            ("BOTTOMPADDING", (0,0), (-1,-1), 5),
        ]))
        e.append(box)
        e += bullet(items)
        e.append(SPACE(2))
    return e

# ─── Section 4 ────────────────────────────────────────────────────────────────
def section4():
    e = []
    e.append(heading("4. Flutter Project Structure"))
    e.append(HR())
    e.append(para("The <b>lib/</b> folder is organised as follows:"))
    tree = [
        "lib/",
        "├── main.dart                   # App entry point",
        "├── config/",
        "│   ├── constants.dart          # API URL, keys, metadata",
        "│   ├── routes.dart             # Route names + GetPage list",
        "│   └── theme.dart              # AppColors + AppTheme",
        "├── data/",
        "│   ├── datasources/",
        "│   │   ├── local/",
        "│   │   │   └── storage_service.dart   # Secure + prefs storage",
        "│   │   └── remote/",
        "│   │       ├── api_client.dart         # Dio singleton + auth interceptor",
        "│   │       ├── auth_api.dart           # Auth HTTP calls",
        "│   │       ├── conversation_api.dart   # Chat HTTP calls",
        "│   │       ├── vocabulary_api.dart     # Vocabulary HTTP calls",
        "│   │       └── ...                     # (other feature APIs)",
        "│   ├── models/",
        "│   │   ├── user_model.dart",
        "│   │   ├── conversation_model.dart",
        "│   │   ├── vocabulary_model.dart",
        "│   │   └── ...                         # (other models)",
        "│   └── repositories/",
        "│       ├── auth_repository.dart",
        "│       ├── conversation_repository.dart",
        "│       └── ...                         # (other repos)",
        "├── services/",
        "│   └── websocket_service.dart  # WS connection & typed streams",
        "├── presentation/",
        "│   ├── bindings/               # GetX DI per route group",
        "│   ├── controllers/            # GetxController per feature",
        "│   ├── screens/                # Full-page widgets",
        "│   │   ├── auth/               # splash, onboarding, login, signup",
        "│   │   ├── home/               # home, discover, search",
        "│   │   ├── conversation/       # list, detail, calls",
        "│   │   ├── profile/            # profile, edit, settings, vocab",
        "│   │   ├── gamification/       # achievements, leaderboard, daily",
        "│   │   ├── quiz/ games/        # quiz, games",
        "│   │   └── practice/           # practice session",
        "│   ├── themes/app_theme.dart   # ThemeData builders",
        "│   └── widgets/                # buttons, inputs, cards, messages",
        "└── utils/",
        "    ├── validators.dart         # Form validation helpers",
        "    └── responsive_util.dart    # Screen-size helpers",
    ]
    e += code(tree)
    return e

# ─── Section 5 ────────────────────────────────────────────────────────────────
def section5():
    e = []
    e.append(heading("5. Application Entry Point — main.dart"))
    e.append(HR())
    e.append(para(
        "Flutter's entry point is the <b>main()</b> function. Before the first frame renders, "
        "LinguaConnect resolves the initial route and theme to avoid a white flash."
    ))
    e.append(SPACE(2))
    steps = [
        ("WidgetsFlutterBinding.ensureInitialized()", "Required before any async work before runApp()."),
        ("SystemChrome.setPreferredOrientations()", "Locks the app to portrait on phones."),
        ("SystemChrome.setSystemUIOverlayStyle()", "Makes the status bar transparent with dark icons."),
        ("_resolveInitialRoute()", "Reads the stored access token from flutter_secure_storage. If a token exists → Routes.home, otherwise → Routes.splash. This prevents a logged-in user from ever seeing the splash/login again."),
        ("_resolveSavedTheme()", "Reads the saved theme preference (light/dark/system) from SharedPreferences before the first frame, eliminating a theme-flash."),
        ("runApp(LinguaConnectApp(…))", "Starts the widget tree. LinguaConnectApp wraps GetMaterialApp with both themes, the initial route, the GetPage list, and locale settings."),
    ]
    rows = [[Paragraph(f"<b>{s}</b>", S("m", fontSize=8, fontName="Courier-Bold", leading=12)),
             Paragraph(d, body)] for s, d in steps]
    t = Table(rows, colWidths=[70*mm, W - 70*mm])
    t.setStyle(TableStyle([
        ("ROWBACKGROUNDS", (0,0), (-1,-1), [WHITE, LIGHT]),
        ("GRID", (0,0), (-1,-1), 0.3, colors.HexColor("#E2E8F0")),
        ("VALIGN", (0,0), (-1,-1), "TOP"),
        ("LEFTPADDING", (0,0), (-1,-1), 6),
        ("TOPPADDING", (0,0), (-1,-1), 5),
        ("BOTTOMPADDING", (0,0), (-1,-1), 5),
    ]))
    e.append(t)
    e.append(SPACE(2))
    e += code([
        "void main() async {",
        "  WidgetsFlutterBinding.ensureInitialized();",
        "  final initialRoute = await _resolveInitialRoute(); // token check",
        "  final savedTheme   = await _resolveSavedTheme();   // pref check",
        "  runApp(LinguaConnectApp(",
        "    initialRoute: initialRoute,",
        "    initialThemeMode: savedTheme,",
        "  ));",
        "}",
    ], label="lib/main.dart — simplified")
    return e

# ─── Section 6 ────────────────────────────────────────────────────────────────
def section6():
    e = []
    e.append(heading("6. Configuration — Constants, Theme, Routes"))
    e.append(HR())

    e.append(heading("6.1 AppConstants (lib/config/constants.dart)", h2))
    e.append(para("Centralises all magic values so changing the API URL or a storage key is a one-liner."))
    rows = [
        ["apiBaseUrl", "'http://localhost:3000'", "REST API base"],
        ["wsBaseUrl", "'ws://localhost:3000'", "WebSocket base"],
        ["apiTimeout", "Duration(seconds: 30)", "Dio timeout"],
        ["keyAccessToken", "'access_token'", "Secure storage key for JWT"],
        ["keyOnboardingDone", "'onboarding_done'", "SharedPreferences flag"],
        ["supportedLanguages", "List<Map> — 13 languages", "Language picker data"],
        ["availableInterests", "List<Map> — 15 interests", "Interest picker data"],
    ]
    t = header_table(
        [Paragraph(h, S("t", fontSize=8.5, textColor=WHITE, fontName="Helvetica-Bold")) for h in ["Constant", "Value", "Purpose"]],
        [[Paragraph(c, S("m2", fontSize=8, fontName="Courier", leading=12) if i == 0 else body) for i, c in enumerate(r)] for r in rows],
        col_widths=[42*mm, 52*mm, W - 94*mm]
    )
    e.append(t)
    e.append(SPACE(3))

    e.append(heading("6.2 AppTheme & AppColors (lib/config/theme.dart)", h2))
    e.append(para(
        "All colours and gradients are defined in <b>AppColors</b>. "
        "<b>AppTheme</b> builds separate <i>ThemeData</i> objects for light and dark mode "
        "that are passed directly to <i>GetMaterialApp</i>."
    ))
    e += bullet([
        "AppColors.primary = 0xFF6366F1 (Indigo) — main brand colour",
        "AppColors.secondary = 0xFF10B981 (Emerald) — accent / success colour",
        "AppColors.primaryGradient — LinearGradient(Indigo → Purple) used on splash, buttons, logo",
        "AppColors.purple, amber, error — semantic colours for gamification and states",
        "AppTheme.lightTheme / darkTheme — Material 3 ColorScheme.fromSeed(...) based themes",
    ])
    e.append(SPACE(3))

    e.append(heading("6.3 Routes (lib/config/routes.dart)", h2))
    e.append(para(
        "All navigation is name-based. <b>Routes</b> is a class of string constants plus "
        "a <b>List&lt;GetPage&gt;</b> that maps each route to a screen widget and an optional Binding."
    ))
    routes = [
        ["Route Name", "Screen", "Binding", "Transition"],
        ["'/'", "SplashScreen", "AuthBinding", "fade"],
        ["'/onboarding'", "OnboardingScreen", "—", "fadeIn"],
        ["'/login'", "LoginScreen", "AuthBinding", "fadeIn"],
        ["'/signup'", "SignupScreen", "AuthBinding", "rightToLeft"],
        ["'/home'", "HomeScreen", "HomeBinding", "fade"],
        ["'/conversations'", "ConversationsListScreen", "ConversationBinding", "rightToLeft"],
        ["'/conversations/detail'", "ConversationDetailScreen", "ConversationBinding", "rightToLeft"],
        ["'/call/audio'", "AudioCallScreen", "—", "upToDown"],
        ["'/profile/vocabulary'", "VocabularyScreen", "HomeBinding", "rightToLeft"],
        ["'/quiz'", "QuizScreen", "HomeBinding", "rightToLeft"],
        ["'/games'", "GamesScreen", "HomeBinding", "rightToLeft"],
    ]
    t = header_table(
        [Paragraph(h, S("t2", fontSize=8.5, textColor=WHITE, fontName="Helvetica-Bold")) for h in routes[0]],
        [[Paragraph(c, S("sm", fontSize=8, fontName="Courier" if i==0 else "Helvetica", leading=12)) for i, c in enumerate(r)] for r in routes[1:]],
        col_widths=[42*mm, 52*mm, 32*mm, W - 126*mm]
    )
    e.append(t)
    return e

# ─── Section 7 ────────────────────────────────────────────────────────────────
def section7():
    e = []
    e.append(heading("7. Data Layer: Models, APIs, Repositories"))
    e.append(HR())

    e.append(heading("7.1 Data Models", h2))
    e.append(para(
        "Every model is a plain Dart class with a <b>fromJson</b> factory and an optional "
        "<b>toJson</b> method. Models are immutable value objects — no business logic."
    ))
    models = [
        ["Model", "Key Fields"],
        ["UserModel", "id, username, email, profilePhotoUrl, nativeLanguages, learningLanguages, xp, level, streak"],
        ["ConversationModel", "id, participants[], lastMessage, unreadCount, createdAt"],
        ["MessageModel", "id, conversationId, senderId, content, type, status, isEdited, isDeleted, reactions[], replyTo, readAt"],
        ["VocabularyEntryModel", "id, word, translation, example, audioPath, languageId, createdAt + audioUrl getter"],
        ["QuizModel", "id, title, questions[], category, difficulty, createdAt"],
        ["GameModel", "id, sessionId, words[], score, status"],
        ["AchievementModel", "id, title, description, icon, xpReward, earnedAt"],
    ]
    t = header_table(
        [Paragraph(h, S("th2", fontSize=8.5, textColor=WHITE, fontName="Helvetica-Bold")) for h in models[0]],
        [[Paragraph(c, S("m3", fontSize=8, fontName="Courier" if i==0 else "Helvetica", leading=12)) for i, c in enumerate(r)] for r in models[1:]],
        col_widths=[40*mm, W - 40*mm]
    )
    e.append(t)
    e.append(SPACE(2))

    e.append(heading("7.2 ApiClient — Dio Singleton (lib/data/datasources/remote/api_client.dart)", h2))
    e.append(para(
        "A singleton <b>Dio</b> instance is created with the base URL and timeout from AppConstants. "
        "Two interceptors are attached:"
    ))
    e += bullet([
        "<b>_AuthInterceptor</b> — reads the JWT from StorageService and adds it as "
        "'Authorization: Bearer …' to every outgoing request. On a 401 response, it "
        "automatically calls POST /auth/refresh, saves the new tokens, and retries the "
        "original request — all transparent to the calling code. Multiple concurrent 401s "
        "are collapsed into a single refresh via a shared Future.",
        "<b>LogInterceptor</b> — logs request/response bodies to the Dart console during development.",
    ])
    e.append(SPACE(2))

    e.append(heading("7.3 Feature APIs", h2))
    e.append(para(
        "Each feature has its own API class that uses ApiClient.instance (the Dio singleton) "
        "and exposes typed async methods. This keeps HTTP details out of controllers."
    ))
    e += code([
        "// Example: vocabulary_api.dart",
        "class VocabularyApi {",
        "  VocabularyApi(this._client);",
        "  final ApiClient _client;",
        "",
        "  Future<List<VocabularyEntryModel>> getEntries() async {",
        "    final res = await _client.get('/vocabulary');",
        "    return (res.data as List).map(VocabularyEntryModel.fromJson).toList();",
        "  }",
        "",
        "  Future<VocabularyEntryModel> createEntry(Map<String,dynamic> body) async {",
        "    final res = await _client.post('/vocabulary', data: body);",
        "    return VocabularyEntryModel.fromJson(res.data as Map<String,dynamic>);",
        "  }",
        "}",
    ])
    e.append(SPACE(2))

    e.append(heading("7.4 Repositories", h2))
    e.append(para(
        "Repositories sit between controllers and APIs. They combine API calls with local "
        "storage operations — for example, after login the AuthRepository calls the API, "
        "then immediately saves the tokens and user to StorageService."
    ))
    e += code([
        "// auth_repository.dart — login method",
        "Future<UserModel> login({String identifier, String password}) async {",
        "  final auth = await _api.login(email: …, password: password);",
        "  await _storage.saveTokens(accessToken: auth.accessToken, …);",
        "  await _storage.saveUserId(auth.userId);",
        "  final user = await _api.getUserById(auth.userId);",
        "  await _storage.saveUser(user);",
        "  return user; // returned to AuthController",
        "}",
    ])
    return e

# ─── Section 8 ────────────────────────────────────────────────────────────────
def section8():
    e = []
    e.append(heading("8. State Management with GetX"))
    e.append(HR())
    e.append(para(
        "LinguaConnect uses <b>GetX</b> for reactive state management. "
        "The core concepts used throughout the app:"
    ))
    e.append(SPACE(2))

    concepts = [
        ("GetxController", "INDIGO",
         "Base class for all feature controllers. Provides onInit() / onClose() "
         "lifecycle hooks. Controllers are registered in Bindings and retrieved via "
         "Get.find<T>()."),
        (".obs (Observables)", "EMERALD",
         "Any variable declared with .obs becomes reactive. Examples: "
         "isLoading.obs, messages.obs (RxList), errorMessage.obs (Rx<String?>). "
         "Changing .value triggers a UI rebuild wherever Obx() wraps that value."),
        ("Obx(() => widget)", "PURPLE",
         "A widget that subscribes to any .obs variables read inside its builder "
         "function. Only rebuilds the specific Obx subtree — not the whole screen."),
        ("Get.offAllNamed(route)", "ORANGE",
         "Navigate to a route and clear the entire back-stack. Used after login "
         "(to prevent going back to splash) and after logout (to prevent going back to home)."),
        ("Get.toNamed(route, arguments: {})", "RED",
         "Navigate to a route with an arguments map. The target screen's controller "
         "reads the map in onInit() via Get.arguments."),
    ]
    for title, color_name, desc in concepts:
        color = {"INDIGO": INDIGO, "EMERALD": EMERALD, "PURPLE": PURPLE, "ORANGE": ORANGE, "RED": RED}[color_name]
        row = Table([[
            colored_box(title, bg=color, fg=WHITE, font_size=8),
            Paragraph(desc, body),
        ]], colWidths=[42*mm, W - 42*mm])
        row.setStyle(TableStyle([
            ("VALIGN", (0,0), (-1,-1), "TOP"),
            ("LEFTPADDING", (0,0), (-1,-1), 4),
            ("TOPPADDING", (0,0), (-1,-1), 4),
            ("BOTTOMPADDING", (0,0), (-1,-1), 4),
            ("BACKGROUND", (0,0), (-1,-1), LIGHT),
            ("GRID", (0,0), (-1,-1), 0.3, colors.HexColor("#E2E8F0")),
        ]))
        e.append(row)
        e.append(SPACE(1))

    e.append(SPACE(2))
    e.append(heading("Controller Example — AuthController", h3))
    e += code([
        "class AuthController extends GetxController {",
        "  final isLoading    = false.obs;        // reactive bool",
        "  final errorMessage = Rx<String?>(null); // reactive nullable string",
        "  final currentUser  = Rx<UserModel?>(null);",
        "",
        "  Future<void> login({String identifier, String password}) async {",
        "    isLoading.value = true;               // triggers Obx rebuild",
        "    errorMessage.value = null;",
        "    try {",
        "      final user = await _repo.login(…);",
        "      currentUser.value = user;",
        "      Get.offAllNamed(Routes.home);       // navigate, clear stack",
        "    } catch (e) {",
        "      errorMessage.value = ApiClient.parseError(e);",
        "    } finally {",
        "      isLoading.value = false;            // triggers Obx rebuild",
        "    }",
        "  }",
        "}",
    ])
    return e

# ─── Section 9 ────────────────────────────────────────────────────────────────
def section9():
    e = []
    e.append(heading("9. Bindings — Dependency Injection"))
    e.append(HR())
    e.append(para(
        "GetX <b>Bindings</b> are classes that register controllers in the DI container "
        "exactly when a route is entered and dispose them when the route is left. "
        "This prevents memory leaks and avoids over-eager instantiation."
    ))
    e.append(SPACE(2))
    e += bullet([
        "<b>Get.put(X, permanent: true)</b> — creates X immediately and keeps it alive for the whole session. Used for AppController and WebSocketService.",
        "<b>Get.lazyPut(() => X, fenix: true)</b> — creates X on first Get.find<X>() call. fenix: true means the controller is recreated if the user navigates away and back.",
        "AuthBinding registers AuthController — active during all auth screens.",
        "HomeBinding registers 11 controllers (AppController, WebSocketService, HomeController, MatchingController, FollowController, ConversationController, ProfileController, GamificationController, NotificationsController, QuizController, GamesController, VocabularyController).",
        "ConversationBinding registers ConversationController + ConversationDetailController for the chat screens.",
    ])
    e.append(SPACE(2))
    e += code([
        "class HomeBinding extends Bindings {",
        "  @override",
        "  void dependencies() {",
        "    Get.put(AppController(), permanent: true);",
        "    Get.put(WebSocketService(), permanent: true); // WS connects here",
        "    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);",
        "    Get.lazyPut<ConversationController>(() => ConversationController(), fenix: true);",
        "    Get.lazyPut<VocabularyController>(() => VocabularyController(), fenix: true);",
        "    // … 6 more controllers",
        "  }",
        "}",
    ], label="lib/presentation/bindings/home_binding.dart")
    return e

# ─── Section 10 ────────────────────────────────────────────────────────────────
def section10():
    e = []
    e.append(heading("10. Navigation & Data Transfer Between Screens"))
    e.append(HR())
    e.append(para(
        "All navigation uses named routes. Data is passed either as an "
        "<b>arguments map</b> (for small payloads) or through the <b>shared controller state</b> "
        "(for larger reactive data already loaded in a GetxController)."
    ))
    e.append(SPACE(2))
    e.append(heading("10.1 Arguments Map Pattern", h2))
    e.append(para("Used when the target screen needs a few IDs or strings to bootstrap itself."))
    e += code([
        "// Caller (conversations list screen) — passes IDs as arguments",
        "Get.toNamed(",
        "  Routes.conversationDetail,",
        "  arguments: {",
        "    'id':           conv.id,",
        "    'partner_name': conv.otherUser.displayName,",
        "    'partner_id':   conv.otherUser.id,",
        "  },",
        ");",
        "",
        "// Target controller reads them in onInit()",
        "@override",
        "void onInit() {",
        "  super.onInit();",
        "  final args     = Get.arguments as Map<String, dynamic>? ?? {};",
        "  conversationId = args['id'] as int? ?? 0;",
        "  partnerName    = args['partner_name'] as String? ?? 'Partner';",
        "  partnerId      = args['partner_id'] as int?;",
        "  _init(); // loads messages, starts WS/polling",
        "}",
    ])
    e.append(SPACE(2))
    e.append(heading("10.2 Shared Controller State Pattern", h2))
    e.append(para(
        "When data is already loaded in a controller that both screens share, "
        "the second screen calls Get.find<T>() to retrieve the same instance."
    ))
    e += bullet([
        "ProfileController is shared between ProfileScreen and EditProfileScreen — edits update the same observable.",
        "VocabularyController is shared between VocabularyScreen and ConversationDetailScreen (long-press 'Save to vocabulary' on a message opens the add-word sheet).",
        "ConversationController (list) and ConversationDetailController (detail) are separate instances but both registered in ConversationBinding.",
    ])
    e.append(SPACE(2))
    e.append(heading("10.3 Navigation Flow Diagram", h2))
    flow = [
        ["Splash", "→ (no token)", "Onboarding", "→ (done)", "Login"],
        ["Splash", "→ (has token)", "Home", "", ""],
        ["Login", "→ (success)", "Home (stack cleared)", "", ""],
        ["Home", "→ tap Messages", "Conversations List", "→ tap item", "Chat Detail"],
        ["Chat Detail", "→ long-press msg", "Vocabulary Add Sheet", "", ""],
        ["Home", "→ tap Discover", "Discover Screen", "", ""],
        ["Profile", "→ tap My Vocabulary", "Vocabulary Screen", "", ""],
    ]
    t = Table(flow, colWidths=[30*mm, 28*mm, 40*mm, 24*mm, W - 122*mm])
    t.setStyle(TableStyle([
        ("FONTNAME", (0,0), (-1,-1), "Helvetica"),
        ("FONTSIZE", (0,0), (-1,-1), 8),
        ("ROWBACKGROUNDS", (0,0), (-1,-1), [WHITE, LIGHT]),
        ("GRID", (0,0), (-1,-1), 0.3, colors.HexColor("#E2E8F0")),
        ("LEFTPADDING", (0,0), (-1,-1), 5),
        ("TOPPADDING", (0,0), (-1,-1), 4),
        ("BOTTOMPADDING", (0,0), (-1,-1), 4),
        ("TEXTCOLOR", (0,0), (0,-1), INDIGO),
        ("FONTNAME", (0,0), (0,-1), "Helvetica-Bold"),
    ]))
    e.append(t)
    return e

# ─── Section 11 ────────────────────────────────────────────────────────────────
def section11():
    e = []
    e.append(heading("11. Real-Time Communication: WebSocket Service"))
    e.append(HR())
    e.append(para(
        "The <b>WebSocketService</b> maintains a persistent WebSocket connection to the "
        "NestJS gateway. It connects automatically when HomeBinding is entered (the user "
        "logs in), and disconnects when the app is closed or the user logs out."
    ))
    e.append(SPACE(2))
    e.append(heading("Connection Lifecycle", h2))
    e += bullet([
        "Connects on onInit() using the stored JWT as a URL query parameter: ws://localhost:3000?token=…",
        "Sends a 'ping' every 25 seconds to keep the connection alive (server responds with 'pong').",
        "On disconnection (error or remote close), schedules a reconnect with exponential back-off: [1, 2, 4, 8, 16, 30, 30, 30] seconds. Max 8 attempts.",
        "Multiple concurrent 401s are collapsed — only one refresh request is sent.",
    ])
    e.append(SPACE(2))
    e.append(heading("Typed Event Streams", h2))
    e.append(para(
        "Each event type has its own broadcast StreamController. Controllers subscribe "
        "to the specific stream they care about using .where() filters."
    ))
    streams = [
        ["Stream", "Event types", "Consumed by"],
        ["messageStream", "new_message, message_edited, message_deleted", "ConversationDetailController"],
        ["typingStream", "typing", "ConversationDetailController"],
        ["readReceiptStream", "message_read", "ConversationDetailController"],
        ["onlineStatusStream", "user_online, user_offline", "ConversationDetailController"],
        ["callEventStream", "incoming_call, call_accepted, call_rejected, call_ended", "CallController"],
        ["matchEventStream", "match_found, match_request", "MatchingController"],
        ["sessionEventStream", "session_accepted", "PracticeSessionController"],
    ]
    t = header_table(
        [Paragraph(h, S("t3", fontSize=8.5, textColor=WHITE, fontName="Helvetica-Bold")) for h in streams[0]],
        [[Paragraph(c, S("s2", fontSize=8, fontName="Courier" if i==0 else "Helvetica", leading=12)) for i, c in enumerate(r)] for r in streams[1:]],
        col_widths=[38*mm, 72*mm, W - 110*mm]
    )
    e.append(t)
    e.append(SPACE(2))
    e.append(heading("WS + REST Hybrid Send", h2))
    e.append(para(
        "Sending a message uses a hybrid approach: the message is sent via <b>REST POST</b> "
        "(which returns the authoritative message ID from the database), not via WebSocket. "
        "Incoming messages from the partner arrive via the WebSocket <b>new_message</b> event. "
        "If WebSocket is unavailable, the controller falls back to polling REST every 3 seconds."
    ))
    return e

# ─── Section 12 ────────────────────────────────────────────────────────────────
def section12():
    e = []
    e.append(heading("12. Authentication Flow"))
    e.append(HR())
    e.append(heading("12.1 Splash Screen (lib/presentation/screens/auth/splash_screen.dart)", h2))
    e.append(para(
        "The splash screen uses two <b>AnimationController</b>s to orchestrate a polished "
        "entry sequence, then navigates after a 5-second hold."
    ))
    e += bullet([
        "logoCtrl (900ms, Curves.elasticOut) — scales and fades the _LogoMark widget from 40% to 100%.",
        "textCtrl (700ms, Curves.easeOut) — fades and slides the app name and tagline upward.",
        "Sequence: 200ms delay → logo animates → 500ms delay → text animates → 4300ms hold → _navigate().",
        "_navigate() checks for a stored token: if present → Routes.home; if absent → checks onboarding_done flag → Routes.onboarding or Routes.login.",
    ])
    e.append(SPACE(2))
    e.append(heading("12.2 _LogoMark Widget", h2))
    e.append(para(
        "A custom widget composing a translucent outer ring, a white circular base with drop shadow, "
        "a globe icon (language / world concept) rendered with the primary gradient via ShaderMask + "
        "BlendMode.srcIn, and a small emerald chat-bubble badge in the bottom-right corner (connection concept). "
        "Entirely vector/widget-based — no raster assets needed."
    ))
    e.append(SPACE(2))
    e.append(heading("12.3 Login Screen", h2))
    e += bullet([
        "TextInputField (email/username) + PasswordInputField → Form with GlobalKey.",
        "AuthController.login() sets isLoading.obs → PrimaryButton shows spinner via Obx().",
        "On success: Get.offAllNamed(Routes.home) — clears the navigation stack.",
        "Google Sign-In via google_sign_in package → AuthController.loginWithGoogle().",
        "Error is displayed in an _ErrorBanner widget (red border container above the button).",
    ])
    e.append(SPACE(2))
    e.append(heading("12.4 Multi-Step Signup", h2))
    e.append(para(
        "The signup screen uses a step-based flow managed by <b>signupStep.obs</b> in AuthController. "
        "Each step collects data via <b>updateSignupData(map)</b>. The final step calls "
        "<b>submitSignup()</b> which sends the combined map to the backend."
    ))
    return e

# ─── Section 13 ────────────────────────────────────────────────────────────────
def section13():
    e = []
    e.append(heading("13. Onboarding Screens (lib/presentation/screens/auth/onboarding_screen.dart)"))
    e.append(HR())
    e.append(para(
        "First-run users see a 3-page onboarding carousel before being sent to login. "
        "The 'onboarding_done' flag is saved to SharedPreferences via StorageService, "
        "so the carousel is shown only once."
    ))
    e.append(SPACE(2))
    e += bullet([
        "Built with a PageView.builder + PageController for swipe navigation.",
        "The scaffold background uses AnimatedContainer(gradient: page.gradient) — the gradient smoothly transitions between pages as the user swipes.",
        "Dot indicators use AnimatedContainer to grow the active dot from 8×8 to 24×8 pixels.",
        "Page 1: Globe icon + 'Learn languages by connecting' — Indigo/Purple gradient.",
        "Page 2: Flag icon + 'Practice with a purpose' — Emerald gradient.",
        "Page 3: Rocket icon + 'Stay motivated, together' — Purple gradient.",
        "Skip button calls _finish() immediately. Next/Get Started buttons advance the page or call _finish().",
        "_finish() calls StorageService.instance.setOnboardingDone() then Get.offAllNamed(Routes.login).",
    ])
    return e

# ─── Section 14 ────────────────────────────────────────────────────────────────
def section14():
    e = []
    e.append(heading("14. Home Screen"))
    e.append(HR())
    e.append(para(
        "The home screen acts as the app's dashboard. After login it is the root of the "
        "navigation stack. It shows the user's profile summary and four quick-action cards "
        "navigating to the main features."
    ))
    e.append(SPACE(2))
    e += bullet([
        "ProfileController loads the current user and their stats (XP, streak, level).",
        "The greeting section shows the user's avatar, name, current streak, and XP progress bar.",
        "Four _ActionCard widgets in a 2×2 grid: Messages (indigo), Discover (emerald), Quiz (purple), Games (amber).",
        "Each _ActionCard has a tinted icon badge, title, subtitle, a gradient stripe, and InkWell ripple feedback.",
        "A bottom navigation bar (BottomNavBar widget) provides tabs: Home, Conversations, Profile.",
    ])
    return e

# ─── Section 15 ────────────────────────────────────────────────────────────────
def section15():
    e = []
    e.append(heading("15. Conversations & Chat"))
    e.append(HR())
    e.append(heading("15.1 Conversations List", h2))
    e += bullet([
        "ConversationController loads the list of conversations from REST on init.",
        "Each row is a ConversationCard widget showing avatar, partner name, last message preview, unread badge, and timestamp.",
        "Tapping a row calls Get.toNamed(Routes.conversationDetail, arguments: {id, partner_name, partner_id}).",
    ])
    e.append(SPACE(2))
    e.append(heading("15.2 Chat Detail Screen", h2))
    e.append(para(
        "The most complex screen. It uses <b>ConversationDetailController</b> which manages "
        "two real-time transport modes simultaneously."
    ))
    e += bullet([
        "Initial load: REST GET /conversations/:id/messages (paginated, sortAsc: true, 50 per page).",
        "Older messages loaded on scroll-to-top via ListView reverse scroll listener.",
        "Messages rendered as MessageBubble widgets — own messages on the right, partner's on the left.",
        "MessageBubble shows: content text, timestamp, edit/delete indicators, reactions, reply preview, read receipts (✓✓).",
        "Long-press on a message shows an options sheet: Copy, Reply, Pin/Unpin, React, Edit, Delete, Save to Vocabulary.",
        "MessageInputBar — pill-shaped input with emoji button, text field, and animated gradient send button.",
        "Typing indicator: isPartnerTyping.obs triggers a '… typing' indicator beneath the message list.",
        "Partner online status shown in the app bar subtitle via partnerIsOnline.obs.",
    ])
    e.append(SPACE(2))
    e.append(heading("15.3 Message Input Bar Widget", h2))
    e += code([
        "// lib/presentation/widgets/message/message_input.dart",
        "// Single pill bar: [emoji icon] [text field] [send button]",
        "Row(",
        "  children: [",
        "    _PillIcon(icon: Icons.emoji_emotions_outlined, …),",
        "    Expanded(child: TextField(controller: ctrl.textController, …)),",
        "    Obx(() => _SendButton(hasText: ctrl.hasText.value, onTap: ctrl.sendMessage)),",
        "  ],",
        ")",
        "// _SendButton shows a gradient circle when text exists, mic icon when empty",
    ])
    return e

# ─── Section 16 ────────────────────────────────────────────────────────────────
def section16():
    e = []
    e.append(heading("16. Voice & Video Calls (LiveKit)"))
    e.append(HR())
    e.append(para(
        "Calls are initiated from the chat detail screen via a call button in the app bar. "
        "The backend creates a LiveKit room and returns a JWT token and server URL to the caller, "
        "which are forwarded to the receiver via a WebSocket 'incoming_call' event."
    ))
    e += bullet([
        "Caller taps the audio/video call button → POST /conversations/:id/call on the REST API.",
        "Backend (NestJS + livekit-server-sdk) creates a LiveKit room, generates tokens for both users, emits 'incoming_call' WS event to the partner.",
        "Partner's app receives the WsCallEvent via callEventStream → shows an incoming call screen.",
        "Partner accepts → CallController responds via WebSocket respondToCall(callId, accepted: true) → backend connects both to the LiveKit room.",
        "AudioCallScreen / VideoCallScreen use the LiveKit Flutter SDK to render local and remote tracks.",
        "CallRatingController handles the post-call rating UI (1–5 stars + comment).",
    ])
    return e

# ─── Section 17 ────────────────────────────────────────────────────────────────
def section17():
    e = []
    e.append(heading("17. Matching System"))
    e.append(HR())
    e.append(para(
        "The matching system finds language partners based on mutual language interests. "
        "Users set matching preferences (language, age range, gender) and the system either "
        "immediately finds a compatible online user or queues them for up to 10 minutes."
    ))
    e += bullet([
        "MatchingController exposes startSearch() / stopSearch() / respondToRequest().",
        "Backend matching algorithm: finds users who speak the language the current user wants to learn, and want to learn the language the current user speaks.",
        "When a match is found, a WsMatchEvent arrives via matchEventStream → MatchingController shows a match-found dialog.",
        "User accepts → a new Conversation is created → Get.toNamed(Routes.conversationDetail, …).",
    ])
    return e

# ─── Section 18 ────────────────────────────────────────────────────────────────
def section18():
    e = []
    e.append(heading("18. Quiz & Games Features"))
    e.append(HR())
    e.append(heading("18.1 Quiz", h2))
    e += bullet([
        "QuizController loads available quiz templates from REST GET /quiz/templates.",
        "User selects a quiz → POST /quiz/start → returns a QuizInstance with questions.",
        "Each question rendered with multiple-choice buttons. Answer recorded via POST /quiz/:id/answer.",
        "Results screen shows score, correct/incorrect breakdown, and XP earned.",
    ])
    e.append(SPACE(2))
    e.append(heading("18.2 Games", h2))
    e += bullet([
        "GamesController loads word-matching game sessions.",
        "Games are built around GameWord entities seeded in the database (word + translation + language).",
        "Word matching game: drag/drop or tap-to-select pairs — score tracked server-side.",
        "Achievements unlocked on milestone scores — notified via WS or REST.",
    ])
    return e

# ─── Section 19 ────────────────────────────────────────────────────────────────
def section19():
    e = []
    e.append(heading("19. Vocabulary Feature"))
    e.append(HR())
    e.append(para(
        "A personal vocabulary notebook. Users save words (with translation, example sentence, "
        "and optional audio recording) directly from the chat or from the vocabulary screen."
    ))
    e.append(SPACE(2))
    e.append(heading("19.1 Backend (NestJS)", h2))
    e += bullet([
        "VocabularyEntry entity: id, user_id (FK → User), language_id (nullable FK → Language), word, translation, example (nullable), audio_path (nullable), timestamps.",
        "CRUD REST endpoints under /vocabulary — all protected by JWT AuthGuard.",
        "Audio upload: POST /vocabulary/:id/audio — FileInterceptor (multer) saves to ./uploads/vocabulary-audio/, validates MIME type (audio/*), max 10 MB.",
    ])
    e.append(SPACE(2))
    e.append(heading("19.2 Frontend", h2))
    e += bullet([
        "VocabularyController manages the list (entries.obs), recording state (isRecording.obs, recordSeconds.obs), and playback state (playingEntryId.obs).",
        "AudioRecorder (record package) captures mic audio to a temp file. AudioPlayer (audioplayers) plays back saved entries.",
        "VocabularyScreen shows entries as VocabularyCard widgets with word, translation, language chip, example, and a play button.",
        "VocabularyAddSheet is a modal bottom sheet with four fields (word, translation, example, language) plus RecordingControls for audio.",
        "The sheet can be opened from the Vocabulary screen (FAB) or from any chat message via long-press → 'Save to vocabulary' (pre-fills the word field with the message text).",
    ])
    e.append(SPACE(2))
    e += code([
        "// Opened from conversation screen with pre-filled word",
        "VocabularyAddSheet.show(",
        "  context,",
        "  ctrl: Get.find<VocabularyController>(),",
        "  initialWord: msg.content.trim(), // message text pre-fills the word field",
        ");",
    ])
    return e

# ─── Section 20 ────────────────────────────────────────────────────────────────
def section20():
    e = []
    e.append(heading("20. Profile & Settings"))
    e.append(HR())
    e += bullet([
        "ProfileController loads the full user profile (languages, interests, stats, reviews) via UserApi.",
        "ProfileScreen shows XP bar, level badge, streak, language chips, interests, and action tiles.",
        "EditProfileScreen: update name, bio, photo (image_picker + multipart upload), languages, interests.",
        "SettingsScreen: toggle dark/light theme (saved via StorageService, applied reactively via AppController), change password, manage notifications.",
        "BlockedUsersScreen: list and unblock users via BlockedUsersController.",
        "MyConnectionsScreen: view followers/following via FollowController.",
    ])
    return e

# ─── Section 21 ────────────────────────────────────────────────────────────────
def section21():
    e = []
    e.append(heading("21. Reusable Widgets"))
    e.append(HR())
    e.append(para("LinguaConnect has a rich widget library in lib/presentation/widgets/:"))
    widgets = [
        ["Widget", "Location", "Description"],
        ["PrimaryButton", "buttons/primary_button.dart", "Gradient-filled button with loading spinner, used for all primary CTAs"],
        ["SecondaryButton", "buttons/secondary_button.dart", "Outlined button for secondary actions"],
        ["TextInputField", "input/text_input_field.dart", "Styled TextFormField with prefix icon, label, and validator"],
        ["PasswordInputField", "input/password_input_field.dart", "TextInputField with show/hide toggle"],
        ["AvatarWidget", "common/avatar_widget.dart", "Circular profile photo with initials fallback and online dot"],
        ["CustomAppBar", "common/custom_app_bar.dart", "Gradient-title app bar used across all feature screens"],
        ["BottomNavBar", "common/bottom_nav_bar.dart", "3-tab navigation bar (Home, Chats, Profile) with active gradient indicator"],
        ["EmptyState", "common/empty_state.dart", "Centered icon + title + subtitle for empty lists"],
        ["LoadingWidget", "common/loading_widget.dart", "Centered CircularProgressIndicator with gradient color"],
        ["ConversationCard", "cards/conversation_card.dart", "Chat list row — avatar, name, last message, unread badge, time"],
        ["UserCard", "cards/user_card.dart", "Discovery/search result card — avatar, name, languages, flag chips"],
        ["MessageBubble", "message/message_bubble.dart", "Chat bubble — content, time, status icons, reactions, reply preview"],
        ["MessageInputBar", "message/message_input.dart", "Pill-shaped input bar — emoji, text field, send/mic button"],
        ["LanguagePickerSheet", "common/language_picker_sheet.dart", "Modal bottom sheet for selecting a language with flag + search"],
    ]
    t = header_table(
        [Paragraph(h, S("t4", fontSize=8.5, textColor=WHITE, fontName="Helvetica-Bold")) for h in widgets[0]],
        [[Paragraph(c, S("w", fontSize=8, fontName="Courier" if i==0 else "Helvetica", leading=12)) for i, c in enumerate(r)] for r in widgets[1:]],
        col_widths=[35*mm, 47*mm, W - 82*mm]
    )
    e.append(t)
    return e

# ─── Section 22 ────────────────────────────────────────────────────────────────
def section22():
    e = []
    e.append(heading("22. Backend: NestJS REST API"))
    e.append(HR())
    e.append(para(
        "The backend is a <b>NestJS 11</b> application using <b>TypeORM</b> and <b>MySQL</b>. "
        "It follows NestJS's module/controller/service architecture."
    ))
    e.append(SPACE(2))
    modules = [
        ["Module", "Endpoints (prefix)", "Responsibility"],
        ["AuthModule", "/auth", "Register, login, Google OAuth, JWT issue/refresh, email verification, password reset"],
        ["UserModule", "/user", "Profile CRUD, photo upload, languages, interests, XP, achievements"],
        ["ConversationModule", "/conversations", "Create conversation, list, messages CRUD, pin, react, calls"],
        ["MatchingModule", "/matching", "Start/stop search, accept/reject match requests, preferences"],
        ["FollowsModule", "/follows", "Follow/unfollow, follower/following lists"],
        ["VocabularyModule", "/vocabulary", "CRUD vocabulary entries, audio upload"],
        ["QuizModule", "/quiz", "Templates, start quiz, submit answer, results"],
        ["GamesModule", "/games", "Game sessions, word matching, scoring"],
        ["LanguagesModule", "/languages", "List supported languages (seeded data)"],
        ["GamificationModule", "/gamification", "Leaderboard, achievements, daily challenge, XP tracking"],
        ["GatewayModule", "ws://:3000", "WebSocket gateway — all real-time events"],
    ]
    t = header_table(
        [Paragraph(h, S("t5", fontSize=8.5, textColor=WHITE, fontName="Helvetica-Bold")) for h in modules[0]],
        [[Paragraph(c, S("b2", fontSize=8, fontName="Courier" if i==0 else "Helvetica", leading=12)) for i, c in enumerate(r)] for r in modules[1:]],
        col_widths=[38*mm, 40*mm, W - 78*mm]
    )
    e.append(t)
    e.append(SPACE(2))
    e.append(heading("JWT Authentication Guard", h2))
    e.append(para(
        "Every protected endpoint uses <b>@UseGuards(AuthGuard)</b>. The guard validates the "
        "Bearer token from the Authorization header, loads the user from the database, and attaches "
        "it to the request object. Controllers access the authenticated user via the "
        "<b>@GetUser()</b> decorator."
    ))
    return e

# ─── Section 23 ────────────────────────────────────────────────────────────────
def section23():
    e = []
    e.append(heading("23. Backend: WebSocket Gateway"))
    e.append(HR())
    e.append(para(
        "The <b>AppGateway</b> class (<code>@WebSocketGateway()</code>) handles all real-time "
        "communication. It uses Socket.IO under the hood (NestJS default)."
    ))
    e.append(SPACE(2))
    events = [
        ["Client → Server", "Server → Client", "Description"],
        ["join_conversation", "—", "Client subscribes to a conversation room"],
        ["send_message", "new_message (to room)", "Broadcasts new message to all room members"],
        ["typing", "typing (to room)", "Forwards typing state to conversation partner"],
        ["mark_read", "message_read (to room)", "Notifies partner of read receipt"],
        ["online_status", "user_online / user_offline", "Broadcasts presence to the user's contacts"],
        ["call_response", "call_accepted / call_rejected", "Forwards call accept/reject to caller"],
        ["ping", "pong", "Keep-alive heartbeat"],
    ]
    t = header_table(
        [Paragraph(h, S("t6", fontSize=8.5, textColor=WHITE, fontName="Helvetica-Bold")) for h in events[0]],
        [[Paragraph(c, body) for c in r] for r in events[1:]],
        col_widths=[42*mm, 42*mm, W - 84*mm]
    )
    e.append(t)
    return e

# ─── Section 24 ────────────────────────────────────────────────────────────────
def section24():
    e = []
    e.append(heading("24. Database Entities & Relationships"))
    e.append(HR())
    e += bullet([
        "<b>User</b> — core entity: id, username, email, passwordHash, nativeLanguages[], learningLanguages[], bio, profilePhoto, xp, level, streak, isVerified",
        "<b>Language</b> — id, name, isoCode, flag (seeded; 13 languages)",
        "<b>UserLanguage</b> — join table: user ↔ language with proficiency and isNative flag",
        "<b>Conversation</b> — id, participants[] (User[]), createdAt",
        "<b>Message</b> — id, conversationId (FK), senderId (FK), content, type, isEdited, isDeleted, isPinned, reactions(JSON), replyToId (self-FK), readAt",
        "<b>ConversationCall</b> — id, conversationId, callerId, callType (audio/video), status, livekitRoomName, startedAt, endedAt",
        "<b>MatchingPreference</b> — userId (FK), targetLanguageId, ageMin, ageMax, preferredGender",
        "<b>VocabularyEntry</b> — id, userId (FK), languageId (nullable FK), word, translation, example, audioPath, timestamps",
        "<b>QuizTemplate / QuizInstance / QuizUserAnswer</b> — full quiz session lifecycle",
        "<b>GameSession / GameWord</b> — word-matching game state",
        "<b>Achievement</b> — id, title, xpReward; UserAchievement — userId ↔ achievementId + earnedAt",
        "<b>UserFollow</b> — followerId + followingId (self-referential many-to-many on User)",
    ])
    return e

# ─── Section 25 ────────────────────────────────────────────────────────────────
def section25():
    e = []
    e.append(heading("25. Key Flutter Patterns Used"))
    e.append(HR())
    patterns = [
        ("StatefulWidget + AnimationController",
         "Used in SplashScreen for the logo entry animation (scale + opacity via CurvedAnimation with Curves.elasticOut) and in OnboardingScreen for the animated gradient background transition."),
        ("ShaderMask + BlendMode.srcIn",
         "Applies a LinearGradient fill to an icon or text widget. Used for the logo globe icon, the app name gradient title, and gradient-filled text in login/signup headers."),
        ("Obx(() => Widget)",
         "GetX's reactive widget. Wraps any widget that depends on an .obs value. When the observable changes, only this subtree rebuilds — not the whole page."),
        ("PageView.builder + PageController",
         "Used in OnboardingScreen for the swipe-able carousel. AnimatedContainer wraps the Scaffold to smoothly crossfade the gradient as pages change."),
        ("Stack + Positioned",
         "Used in the _LogoMark widget to overlay the chat-bubble badge on the bottom-right of the globe icon circle, and in MessageBubble for reactions overlay."),
        ("ListView.builder (reverse: true)",
         "The messages list uses reverse: true so the newest messages are always at the bottom without manual scrolling. Scroll-to-top triggers loading older messages."),
        ("WidgetsBinding.instance.addPostFrameCallback",
         "Used after new messages arrive to scroll to the bottom of the list in the next frame — after the new item has been laid out."),
        ("GlobalKey<FormState>",
         "Used on login and signup forms. form.validate() triggers all validators simultaneously; form.save() collects values."),
        ("KeepAlive / AutomaticKeepAlive",
         "Tab screens that should not be rebuilt when switching tabs implement AutomaticKeepAliveClientMixin to preserve their scroll position and state."),
        ("Singleton services",
         "ApiClient, StorageService, and WebSocketService are all singletons (using private constructors and static instance fields) — ensuring a single Dio instance, a single storage handle, and a single WebSocket connection throughout the app lifetime."),
    ]
    for title, desc in patterns:
        row = Table([[
            Paragraph(f"<b>{title}</b>", S("pt", fontSize=8.5, fontName="Helvetica-Bold", leading=13, textColor=SLATE)),
            Paragraph(desc, body),
        ]], colWidths=[52*mm, W - 52*mm])
        row.setStyle(TableStyle([
            ("VALIGN", (0,0), (-1,-1), "TOP"),
            ("BACKGROUND", (0,0), (0,0), LIGHT),
            ("GRID", (0,0), (-1,-1), 0.3, colors.HexColor("#E2E8F0")),
            ("LEFTPADDING", (0,0), (-1,-1), 6),
            ("TOPPADDING", (0,0), (-1,-1), 5),
            ("BOTTOMPADDING", (0,0), (-1,-1), 5),
        ]))
        e.append(row)
        e.append(SPACE(1))
    return e

# ─── Section 26 ────────────────────────────────────────────────────────────────
def section26():
    e = []
    e.append(heading("26. Summary & Conclusion"))
    e.append(HR())
    e.append(para(
        "<b>LinguaConnect</b> demonstrates a production-quality full-stack Flutter application "
        "covering all major aspects of mobile development:"
    ))
    e.append(SPACE(2))

    summary = [
        ["Area", "Implementation"],
        ["Architecture", "Clean layered architecture (Config → Data → Services → Presentation) with strict separation of concerns"],
        ["State Management", "GetX reactive state (.obs, Obx, GetxController) — no StatefulWidget boilerplate for business logic"],
        ["Navigation", "Named routes with typed arguments maps, Bindings for scoped DI, stack-clearing transitions"],
        ["Networking", "Dio singleton with automatic JWT injection and transparent token refresh on 401"],
        ["Real-time", "WebSocket service with typed event streams, exponential back-off reconnect, REST fallback polling"],
        ["Authentication", "JWT + Refresh tokens, Google OAuth2, email verification, password reset, secure storage"],
        ["Features", "Chat, voice/video calls, matching, quiz, games, vocabulary, profile, gamification"],
        ["UI/UX", "Material 3 themes, light/dark mode, gradient animations, custom widgets, onboarding carousel"],
        ["Backend", "NestJS 11 modular REST API + WebSocket gateway, TypeORM + MySQL, LiveKit for calls"],
    ]
    t = header_table(
        [Paragraph(h, S("t7", fontSize=8.5, textColor=WHITE, fontName="Helvetica-Bold")) for h in summary[0]],
        [[Paragraph(c, S("b3", fontSize=8.5, fontName="Helvetica-Bold" if i==0 else "Helvetica", leading=13)) for i, c in enumerate(r)] for r in summary[1:]],
        col_widths=[38*mm, W - 38*mm]
    )
    e.append(t)
    e.append(SPACE(6))

    footer = Table([[
        colored_box("LinguaConnect — Learn Languages, Make Friends", bg=INDIGO, fg=WHITE, font_size=10)
    ]], colWidths=[W])
    footer.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,-1), INDIGO),
        ("TOPPADDING", (0,0), (-1,-1), 10),
        ("BOTTOMPADDING", (0,0), (-1,-1), 10),
    ]))
    e.append(footer)
    return e

# ─── Page number footer callback ─────────────────────────────────────────────
def add_page_number(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(MID)
    page_num = canvas.getPageNumber()
    if page_num > 2:  # skip cover + TOC
        canvas.drawRightString(
            A4[0] - 20*mm, 12*mm,
            f"LinguaConnect Technical Report  •  Page {page_num}"
        )
        # left: thin indigo bar
        canvas.setStrokeColor(INDIGO)
        canvas.setLineWidth(1)
        canvas.line(20*mm, 14*mm, A4[0] - 20*mm, 14*mm)
    canvas.restoreState()

# ─── Build document ───────────────────────────────────────────────────────────
story = []
story += cover_page()
story += toc()
story += section1()
story.append(PageBreak())
story += section2()
story.append(PageBreak())
story += section3()
story.append(PageBreak())
story += section4()
story.append(PageBreak())
story += section5()
story += section6()
story.append(PageBreak())
story += section7()
story.append(PageBreak())
story += section8()
story.append(PageBreak())
story += section9()
story += section10()
story.append(PageBreak())
story += section11()
story.append(PageBreak())
story += section12()
story.append(PageBreak())
story += section13()
story += section14()
story += section15()
story.append(PageBreak())
story += section16()
story += section17()
story += section18()
story.append(PageBreak())
story += section19()
story.append(PageBreak())
story += section20()
story += section21()
story.append(PageBreak())
story += section22()
story.append(PageBreak())
story += section23()
story += section24()
story.append(PageBreak())
story += section25()
story.append(PageBreak())
story += section26()

doc.build(story, onFirstPage=add_page_number, onLaterPages=add_page_number)
print(f"PDF generated: {OUTPUT}")
