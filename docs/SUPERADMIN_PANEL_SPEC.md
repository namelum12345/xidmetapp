# Superadmin panel — tələblər

## Rol
- Firestore `users/{uid}.role` ∈ `superadmin` | `super_admin`.
- Yalnız `/super/...` (admin `/admin`-ə yönləndirilir — `RoleRouterService`).

## Alt naviqasiya (4 tab) — **tam yol ilə `GoRouter.go`**
1. Dashboard — `/super/dashboard`
2. Adminlər — `/super/admins`
3. Analitika — `/super/analytics`
4. Parametrlər — `/super/settings`

**Qayda:** `StatefulNavigationShell.goBranch` istifadə olunmur; hər vurğuşda `GoRouter.of(context).go(AppRoutes.super…)` (marketplace və admin ilə eyni).

## Tam ekran marshrutlar (`parentNavigatorKey: root`)
- `/super/reports`, `/super/monetization`, `/super/permissions`, `/super/audit`, `/super/ban`, `/super/notifications`
- İdarəetmə: `/super/manage/users|workers|jobs|chats` (admin shell-ə çıxmadan)

Dashboard kartları: **`context.push`** (geri düyməsi ilə shell-ə qayıtmaq üçün).

## Məlumat
- Dashboard stat kartları: birbaşa Firestore `StreamBuilder`.
- Admin idarəetməsi: `SuperadminControlService.usersStream()` — sorğu indeks/xəta riskini azaltmaq üçün məhdudiyyət + client sıralama (əgər tətbiq olunubsa).

## UI qaydası
- Shell tab səhifələri: **`ColoredBox` + scroll**, əlavə `Scaffold` + geri düyməsi **yox** (istisna: yalnız `push` ilə açılan tam ekranlar).
