# Admin panel — tələblər (yenidənqurma üçün)

## Rol və giriş
- Yalnız Firestore `users/{uid}.role == 'admin'` (superadmin ayrıca `/super`-də).
- Marshrut prefiksi: `/admin/...` — `RoleRouterService` admini super səhifələrə buraxmır.

## Alt naviqasiya (6 tab)
Eyni sıra ilə tam yollar — **həmişə `GoRouter.go(AppRoutes.*)`** (StatefulShell `goBranch` yox):
1. Panel — `/admin/dashboard`
2. İstifadəçilər — `/admin/users`
3. İcraçılar — `/admin/workers`
4. Elanlar — `/admin/jobs`
5. Mesajlar (söhbətlər) — `/admin/chats`
6. Profil — `/admin/profile`

## Məlumat mənbələri
- **AdminDataService**: `users`, `workers` real-time; elanlar **JobCatalogService** üzərindən.
- Dashboard stat kartları: birbaşa Firestore `StreamBuilder` (kolleksiya sayları).
- Şikayətlər: `/admin/reports` və ya tam ekran `AdminReportsScreen` (`SuperReportsScreen` UI).

## Ekranlar
- **Dashboard**: kartlar → müvafiq taba `go`.
- **Users**: siyahı, ban, sil (`AdminDataService`).
- **Workers**: siyahı, təsdiq, deaktiv — **tab daxilində AppBar + `pop` olmamalı** (shell içindədir).
- **Jobs**: filter, lifecycle, sil, detala `push`.
- **Chats**: bütün `chats` (staff oxuyur) — `orderBy` olmadan və ya etibarlı sıralama (köhnə sənədlərdə `lastMessageAt` yoxdursa).
- **Profile**: çıxış, qısa keçid icraçı tabına.

## Əlavə marshrut
- `/admin/chat/:threadId` — `ChatScreen(readOnly: true)`.

## Asılı qalan kod (silinməyib)
- `AdminDataService`, `AdminLogService`, `admin_models.dart`, `admin_*_row.dart`, `admin_stat_card.dart`, `stream_query_stat_cards.dart`.

## Bilinən problemlər (həll yolu)
- Tab düymələri boş qalırdı → **yalnız tam path ilə `go`**.
- Workers ekranı `Scaffold` + geri düyməsi shell-i pozurdu → **sadə scroll siyahı**.

Superadmin üçün paralel sənəd: `docs/SUPERADMIN_PANEL_SPEC.md`.
