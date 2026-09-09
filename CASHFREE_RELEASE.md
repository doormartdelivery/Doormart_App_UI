# Cashfree / Play Store release

The backend selects the Cashfree environment; changing a Flutter `.env` Cashfree
value does not switch payment servers. Release apps require a production session.

1. In the **Render service → Environment** settings, set `NODE_ENV=production`,
   `CASHFREE_ENV=production`, `CASHFREE_CLIENT_ID` and `CASHFREE_CLIENT_SECRET`
   to the live Payment Gateway keys from Cashfree. Keep these keys off the app.
   Redeploy the backend with the matching changes in `Doormart_App_backend`.
   Production startup rejects sandbox configuration; check settings before deploying.
2. Ensure the Cashfree merchant account is activated and transactions are enabled.
   If order creation returns “transactions are not enabled for your payment gateway
   account”, resolve activation with Cashfree support. Changing the SDK cannot enable
   a disabled account. Use keys for the selected environment.
3. The public backend must use HTTPS. Cashfree success/webhook URLs are derived
   from the incoming host and protocol; your proxy must supply `X-Forwarded-Proto: https`.
   The routes are `/api/payments/cashfree/success` and
   `/api/payments/cashfree/webhook`. The legacy `CASHFREE_RETURN_URL` and
   `CASHFREE_NOTIFY_URL` environment values are not used by this implementation.
4. The included `release-config.json` points to the Render backend found in this
   project: `https://doormart-app-backend-1.onrender.com`. If your service hostname
   changes, update it before building. For a different deployment use:

   ```json
   {
     "API_BASE_URL": "https://YOUR_BACKEND/api",
     "SOCKET_URL": "https://YOUR_BACKEND",
     "PUBLIC_BASE_URL": "https://YOUR_BACKEND",
     "FRONTEND_URL": "https://YOUR_FRONTEND"
   }
   ```

5. Build with a version code higher than every existing Play upload:

   ```sh
   flutter build appbundle --release --dart-define-from-file=release-config.json --build-number=NEXT_PLAY_VERSION_CODE
   ```

6. Upload to a Play testing track and install through Google Play. Confirm a small
   live UPI payment, server-verified order creation, cancellation/retry, and return
   from the UPI app before promoting the release. A local analysis or build cannot
   verify merchant activation or real payment success.

References: [Cashfree Flutter integration](https://www.cashfree.com/docs/payments/online/mobile/flutter),
[payment troubleshooting](https://www.cashfree.com/docs/api-reference/integration-troubleshooting/payments-ts),
[SDK troubleshooting](https://www.cashfree.com/docs/api-reference/integration-troubleshooting/sdk-ts).
