  This is a Java/Spring MVC web application using MongoDB, JSP, and AngularJS. Here are the security issues found,
  ordered by severity:

  ---
  HIGH Severity

  1. No CSRF Protection — Zero CSRF tokens or validation anywhere in the codebase. Every POST endpoint is vulnerable —
  any malicious site visited by a logged-in user can perform actions on their behalf (change settings, add/remove users,
   upload/delete documents).

  2. Predictable Token Generation (IdGenerator.java:44-61) — Security tokens are generated from
  System.currentTimeMillis() encoded in base-26. An attacker who knows the approximate generation time can brute-force
  the token trivially. These tokens are used for license/auth purposes.

  3. License Token Auth Bypass (ContainerCommon.java:349-358) — The ?lic= URL parameter provides full authentication
  bypass using license tokens. Combined with predictable token generation, an attacker who knows a user's key can
  predict their token and gain full access without login.

  4. CORS Misconfiguration (LightweightAuthServlet.java:68-90) — The auth servlet reflects any Origin header back with
  Access-Control-Allow-Credentials: true, allowing any website to make authenticated cross-origin requests to the auth
  endpoint.

  ---
  MEDIUM Severity

  5. XSS — Reflected (WMFFooter.jsp:2-3, 22, 27) — meetId and topicId request parameters injected directly into onclick
  handlers without encoding.

  6. XSS — Stored via trustAsHtml (tinymce-ng.js:27,123 and many JSPs) — $sce.trustAsHtml() explicitly bypasses
  AngularJS's XSS protection on user-supplied wiki/comment content rendered via ng-bind-html.

  7. Path Traversal — Log File Read (AdminLogFile.jsp:17-32) — The fn parameter is used to construct file paths with no
  ../ sanitization, allowing arbitrary file reads from the server.

  8. Path Traversal — File Upload (ProjectDocsController.java:1105-1116) — Temp file names only require a ~tmp prefix —
  a name like ~tmp/../../../malicious.war writes outside the intended directory.

  9. Path Traversal — Icon Servlet (IconServlet.java:68-135) — User-supplied filenames from URLs used to construct file
  paths with minimal validation.

  10. Insecure Cookies (AuthRequest.java:557-573) — Auth cookies set without HttpOnly or Secure flags, enabling
  JavaScript theft and transmission over plain HTTP.

  11. PBKDF2 with 10 Iterations (PasswordEncrypter.java:34) — OWASP recommends 600,000+ iterations. With 10, any leaked
  password hash is cracked instantly.

  12. Open Redirects (MainTabsViewControler.java:272,465, EmergencyConfigServlet.java:134) — The go parameter is used in
   sendRedirect() without origin validation, enabling phishing via redirect.

  13. No Security Headers — Missing X-Frame-Options, Content-Security-Policy, Strict-Transport-Security,
  X-Content-Type-Options, making the app vulnerable to clickjacking and other attacks.

  14. Credentials in URLs (AttachmentRecord.java:884) — License tokens passed as URL query parameters, exposing them in
  server logs, browser history, and Referer headers.

  ---
  LOW Severity

  15. Weak Random (ContainerCommon.java:275-303) — Uses java.util.Random instead of SecureRandom for generating access
  tokens.

  16. No File Upload Validation (ProjectDocsController.java:1095-1127) — No content-type, extension, or magic-byte
  validation on uploads. Any file type (including JSP web shells) can be uploaded.

  ---
  Priority Recommendations

  1. Immediately: Add CSRF protection (Spring Security's built-in CSRF filter)
  2. Immediately: Replace IdGenerator.generateKey() with SecureRandom-based token generation
  3. Immediately: Fix the CORS policy to whitelist specific origins
  4. Soon: Sanitize all file path inputs against traversal, add HttpOnly/Secure to cookies, increase PBKDF2 iterations
  to 600,000+
  5. Soon: Remove $sce.trustAsHtml() usage and properly sanitize HTML output, validate redirect URLs against a whitelist

  Would you like me to dive deeper into any of these, or start working on fixes for specific issues?
