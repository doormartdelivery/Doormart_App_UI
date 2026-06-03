Frontend dashboard ownership layout:

- `shared/auth/`
  - Shared login and auth provider/service
- `routing/`
  - Route maps split by dashboard
- `customer/`
  - Customer-owned providers and services
- `delivery/`
  - Delivery-owned providers
- `admin/`
  - Admin-owned providers
- `super_admin/`
  - Super admin-owned providers
- `operations/`
  - Cross-dashboard operational services like analytics and location

Notes:

- Existing `lib/views/...` screen files still render the UI, but route ownership is now split by dashboard in `lib/features/routing/`.
- Legacy files in `lib/providers` and `lib/services` are compatibility exports. New work should go into `lib/features/...`.
