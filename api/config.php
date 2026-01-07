<?php
/**
 * Szybka Fucha - Database Configuration
 * 
 * WAŻNE: Zmień hasło poniżej na prawdziwe hasło użytkownika MySQL!
 */

// Database credentials
define('DB_HOST', 'localhost');
define('DB_NAME', 'szybkafucha_users');
define('DB_USER', 'szybkafucha_admin');
define('DB_PASS', 'Nomysz260709!');  // ← ZMIEŃ TO!

// Allowed origins for CORS (your domain)
define('ALLOWED_ORIGIN', 'https://szybkafucha.app');

// Error reporting (set to 0 in production after testing)
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// Timezone
date_default_timezone_set('Europe/Warsaw');
